const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// 1️⃣ Notify others when a new post is created
exports.notifyOthersOnPost = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snap, context) => {
    const postData = snap.data();
    const posterId = postData.userId; // user who created the post

    const usersSnapshot = await admin.firestore().collection('users').get();

    const tokens = [];
    usersSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.fcmToken && data.uid !== posterId) {
        tokens.push(data.fcmToken);
      }
    });

    if (tokens.length === 0) return null;

    const message = {
      notification: {
        title: "New Post",
        body: `${postData.userName || 'Someone'} posted: ${postData.title || 'Check it out!'}`,
      },
      data: {
        screen: "notifications",
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(message);
    console.log('Notifications sent for new post:', response.successCount);
    return null;
  });

// 2️⃣ Send event reminders 30 minutes before event starts
exports.sendEventReminders = functions.pubsub.schedule('every 1 minutes').onRun(async (context) => {
  const now = new Date();
  const nextMinute = new Date(now.getTime() + 60000);

  const snapshot = await admin.firestore().collection('events')
    .where('reminderSent', '==', false)
    .get();

  snapshot.forEach(async (doc) => {
    const event = doc.data();
    const eventTime = event.date.toDate();
    const reminderTime = new Date(eventTime.getTime() - 30 * 60 * 1000);

    if (reminderTime >= now && reminderTime <= nextMinute) {
      const userDoc = await admin.firestore().collection('users').doc(event.userId).get();
      const token = userDoc.data().fcmToken;-

      if (token) {
        await admin.messaging().send({
          token: token,
          notification: {
            title: "Upcoming Event",
            body: `Your event "${event.eventName}" starts in 30 minutes!`,
          },
        });
      }
      await doc.ref.update({ reminderSent: true });
      console.log(`Reminder sent for event: ${event.eventName}`);
    }
  });
});
