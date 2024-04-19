const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Cloud Firestore triggers ref: https://firebase.google.com/docs/functions/firestore-events
exports.sendDummyNotification = functions.https.onRequest((req, res) => {
  return admin.messaging().sendToTopic("placeOrder", {
    notification: {
      title: "Dummy Title",
      body: "This is a dummy notification body.",
      clickAction: "FLUTTER_NOTIFICATION_CLICK",
    },
  }).then(() => {
    res.status(200).send("Notification sent successfully");
  }).catch(error => {
    res.status(500).send("Error sending notification: " + error);
  });
});
