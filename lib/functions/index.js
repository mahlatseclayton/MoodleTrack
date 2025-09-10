const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
admin.initializeApp();

// 1️⃣ Notify only the event creator when a new event is created
exports.notifyOnNewEvent = functions.firestore
    .document("events/{eventId}")
    .onCreate(async (snap, context) => {
      const eventData = snap.data();
      const eventCreatorStudentId = eventData.userId; // student number

      // Find the event creator user
      const usersSnapshot = await admin.firestore().collection("users")
          .where("fcmToken", "!=", "no-token")
          .get();

      let creatorFcmToken = null;

      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        const userStudentId = userData.email ? userData.email.split("@")[0] : null;

        if (userStudentId === eventCreatorStudentId) {
          creatorFcmToken = userData.fcmToken;
          break;
        }
      }

      if (!creatorFcmToken) {
        console.log("No FCM token found for event creator");
        return null;
      }

      const message = {
        token: creatorFcmToken,
        notification: {
          title: "Event Created Successfully ✅",
          body: `Your event "${eventData.eventName}" has been created!`,
        },
        data: {
          screen: "events",
          eventId: context.params.eventId,
          type: "event_created",
        },
      };

      try {
        await admin.messaging().send(message);
        console.log("Event creation notification sent to creator");
      } catch (error) {
        console.error("Error sending event notification:", error);
      }

      return null;
    });

// 2️⃣ Send event reminders 10 minutes before event starts (to event creator only)
exports.sendEventReminders = functions.pubsub.schedule("every 1 minutes")
    .onRun(async (context) => {
      const now = new Date();
      const tenMinutesFromNow = new Date(now.getTime() + 10 * 60 * 1000);

      try {
        const eventsSnapshot = await admin.firestore().collection("events")
            .where("date", ">=", now)
            .where("date", "<=", tenMinutesFromNow)
            .where("reminderSent", "!=", true)
            .get();

        const promises = [];

        for (const doc of eventsSnapshot.docs) {
          const event = doc.data();

          if (!event.date || !event.userId) continue;

          const eventTime = event.date.toDate();
          const timeUntilEvent = eventTime.getTime() - now.getTime();

          // Send reminder if event is within 10 minutes and not already reminded
          if (timeUntilEvent <= 10 * 60 * 1000 && timeUntilEvent > 0) {
            // Find user by student number (from email)
            const usersSnapshot = await admin.firestore().collection("users")
                .where("fcmToken", "!=", "no-token")
                .get();

            let userFcmToken = null;

            for (const userDoc of usersSnapshot.docs) {
              const userData = userDoc.data();
              const userStudentId = userData.email ? userData.email.split("@")[0] : null;

              if (userStudentId === event.userId) {
                userFcmToken = userData.fcmToken;
                break;
              }
            }

            if (userFcmToken) {
              const message = {
                token: userFcmToken,
                notification: {
                  title: "Event Starting Soon ⏰",
                  body: `"${event.eventName}" starts in ${Math.ceil(timeUntilEvent / 60000)} minutes!`,
                },
                data: {
                  screen: "events",
                  eventId: doc.id,
                  type: "reminder",
                },
              };

              const sendPromise = admin.messaging().send(message)
                  .then(async () => {
                    console.log(`Reminder sent for event: ${event.eventName} to student ${event.userId}`);
                    // Mark as reminder sent
                    await doc.ref.update({
                      reminderSent: true,
                      lastReminderSent: admin.firestore.FieldValue.serverTimestamp(),
                    });
                  })
                  .catch((error) => {
                    console.error(`Failed to send reminder for ${event.eventName}:`, error);
                  });

              promises.push(sendPromise);
            } else {
              console.log(`No user found with student number: ${event.userId} for event reminder`);
            }
          }
        }

        await Promise.all(promises);
        console.log(`Processed ${promises.length} event reminders`);
      } catch (error) {
        console.error("Error in event reminders function:", error);
      }

      return null;
    });

// 3️⃣ Monitor Moodle notifications and send alerts to individual users
exports.monitorMoodleNotifications = functions.pubsub.schedule("every 5 minutes")
    .onRun(async (context) => {
      try {
        console.log("Checking for Moodle notifications...");

        // Get all users with Moodle tokens
        const usersSnapshot = await admin.firestore().collection("users")
            .where("moodleToken", "!=", null)
            .where("fcmToken", "!=", "no-token")
            .get();

        if (usersSnapshot.empty) {
          console.log("No users with Moodle tokens found");
          return null;
        }

        const processingPromises = [];

        for (const userDoc of usersSnapshot.docs) {
          const userData = userDoc.data();
          const promise = processUserMoodleNotifications(userDoc.id, userData);
          processingPromises.push(promise);
        }

        await Promise.all(processingPromises);
        console.log("Moodle notification check completed");
      } catch (error) {
        console.error("Error in Moodle notification monitoring:", error);
      }

      return null;
    });

// Helper function to process Moodle notifications for a single user
async function processUserMoodleNotifications(userDocId, userData) {
  try {
    const {moodleToken, fcmToken, email, lastMoodleCheck} = userData;

    if (!moodleToken || fcmToken === "no-token") {
      return;
    }

    // Get notifications from Moodle
    const notifications = await getMoodleNotifications(moodleToken, lastMoodleCheck);

    if (notifications && notifications.length > 0) {
      // Extract student number from email for logging
      const studentNumber = email ? email.split("@")[0] : "unknown";
      console.log(`Found ${notifications.length} new notifications for user ${studentNumber}`);

      // Send notification for each new alert
      for (const notification of notifications) {
        await sendMoodleNotification(fcmToken, notification, studentNumber);
      }

      // Update last check time
      await admin.firestore().collection("users").doc(userDocId).update({
        lastMoodleCheck: admin.firestore.FieldValue.serverTimestamp(),
        lastMoodleNotificationCount: notifications.length,
      });
    }
  } catch (error) {
    console.error(`Error processing Moodle notifications for user ${userDocId}:`, error);
  }
}

// Get Moodle notifications using REST API
async function getMoodleNotifications(moodleToken, sinceDate = null) {
  try {
    let url = `https://courses.ms.wits.ac.za/moodle/webservice/rest/server.php?wstoken=${moodleToken}&wsfunction=core_message_get_messages&moodlewsrestformat=json`;

    if (sinceDate) {
      const unixTimestamp = Math.floor(sinceDate.toDate().getTime() / 1000);
      url += `&min_time=${unixTimestamp}`;
    }

    const response = await axios.get(url, {timeout: 10000});

    if (response.data && response.data.messages) {
      return response.data.messages.filter((msg) =>
        msg.timecreated > (sinceDate ? Math.floor(sinceDate.toDate().getTime() / 1000) : 0),
      );
    }

    return [];
  } catch (error) {
    console.error("Error fetching Moodle notifications:", error.message);
    return [];
  }
}

// Send FCM notification for Moodle alert
async function sendMoodleNotification(fcmToken, moodleNotification, studentNumber) {
  try {
    const message = {
      token: fcmToken,
      notification: {
        title: "📚 New Moodle Notification",
        body: `${moodleNotification.subject || "New update"} from ${moodleNotification.userfromfullname || "Moodle"}`,
      },
      data: {
        screen: "notifications",
        type: "moodle_alert",
        notificationId: moodleNotification.id.toString(),
        courseId: moodleNotification.contexturl || "",
        timestamp: new Date().toISOString(),
      },
    };

    await admin.messaging().send(message);
    console.log(`Moodle notification sent to student ${studentNumber}`);
  } catch (error) {
    console.error(`Failed to send Moodle notification to student ${studentNumber}:`, error);
  }
}

// 4️⃣ TEST FUNCTION: Send test notification to current user only
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    return {success: false, message: "Authentication required"};
  }

  try {
    const userId = context.auth.uid;
    const userDoc = await admin.firestore().collection("users").doc(userId).get();

    if (!userDoc.exists) {
      return {success: false, message: "User not found"};
    }

    const userData = userDoc.data();

    if (!userData.fcmToken || userData.fcmToken === "no-token") {
      return {success: false, message: "FCM token not found for user"};
    }

    const message = {
      token: userData.fcmToken,
      notification: {
        title: "Test Notification ✅",
        body: "This is a test notification from Firebase! 🎉",
      },
      data: {
        screen: "notifications",
        type: "test",
        timestamp: new Date().toISOString(),
      },
    };

    await admin.messaging().send(message);
    console.log(`Test notification sent to user: ${userId}`);

    return {success: true, message: "Test notification sent successfully"};
  } catch (error) {
    console.error("Error sending test notification:", error);
    return {success: false, message: error.message};
  }
});

// 5️⃣ Send notification to specific user by UID
exports.sendToUser = functions.https.onCall(async (data, context) => {
  const {uid, title, body} = data;

  if (!uid || !title || !body) {
    return {success: false, message: "Missing required parameters"};
  }

  try {
    const userDoc = await admin.firestore().collection("users").doc(uid).get();

    if (!userDoc.exists) {
      return {success: false, message: "User not found"};
    }

    const userData = userDoc.data();

    if (!userData.fcmToken || userData.fcmToken === "no-token") {
      return {success: false, message: "FCM token not found for user"};
    }

    const message = {
      token: userData.fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        screen: "notifications",
        type: "direct",
        timestamp: new Date().toISOString(),
      },
    };

    await admin.messaging().send(message);
    console.log(`Notification sent to user: ${uid}`);

    return {success: true, message: "Notification sent successfully"};
  } catch (error) {
    console.error("Error sending user notification:", error);
    return {success: false, message: error.message};
  }
});

// 6️⃣ Manual trigger for Moodle notification check for current user only
exports.manualMoodleCheck = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    return {success: false, message: "Authentication required"};
  }

  try {
    const userId = context.auth.uid;
    const userDoc = await admin.firestore().collection("users").doc(userId).get();

    if (!userDoc.exists) {
      return {success: false, message: "User not found"};
    }

    const userData = userDoc.data();

    if (!userData.moodleToken || !userData.fcmToken || userData.fcmToken === "no-token") {
      return {success: false, message: "Moodle token or FCM token not found"};
    }

    await processUserMoodleNotifications(userId, userData);

    return {success: true, message: "Moodle notification check completed"};
  } catch (error) {
    console.error("Error in manual Moodle check:", error);
    return {success: false, message: error.message};
  }
});

// 7️⃣ Get user by student number and send notification
exports.sendToStudent = functions.https.onCall(async (data, context) => {
  const {studentNumber, title, body} = data;

  if (!studentNumber || !title || !body) {
    return {success: false, message: "Missing required parameters"};
  }

  try {
    // Find user by student number (extracted from email)
    const usersSnapshot = await admin.firestore().collection("users")
        .where("fcmToken", "!=", "no-token")
        .get();

    let userFcmToken = null;
    let userUid = null;

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userStudentId = userData.email ? userData.email.split("@")[0] : null;

      if (userStudentId === studentNumber) {
        userFcmToken = userData.fcmToken;
        userUid = userDoc.id;
        break;
      }
    }

    if (!userFcmToken) {
      return {success: false, message: "User not found or no FCM token"};
    }

    const message = {
      token: userFcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        screen: "notifications",
        type: "direct",
        timestamp: new Date().toISOString(),
      },
    };

    await admin.messaging().send(message);
    console.log(`Notification sent to student: ${studentNumber} (UID: ${userUid})`);

    return {success: true, message: "Notification sent successfully"};
  } catch (error) {
    console.error("Error sending student notification:", error);
    return {success: false, message: error.message};
  }
});