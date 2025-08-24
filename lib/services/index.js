exports.notifyOthersOnPost = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snap, context) => {
    const postData = snap.data();
    const posterId = postData.userId; // <-- use userId instead of authorId

    // Get all user tokens except the poster
    const usersSnapshot = await admin.firestore().collection('users')
//      .where('uid', '!=', posterId)
//      .get();

    const tokens = [];
    usersSnapshot.forEach(doc => {
      if (doc.data().fcmToken) tokens.push(doc.data().fcmToken);
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
    console.log('Notifications sent:', response.successCount);
  });
