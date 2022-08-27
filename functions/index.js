const functions = require("firebase-functions");
// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");

admin.initializeApp(functions.config().firebase);


const runtimeOpts = {
  timeoutSeconds: 540,
  memory: "256MB",
};

exports.addAudioTagToSessions = functions.runWith(runtimeOpts)
    .https.onRequest(
        (req, res) => {
          const Sessions =
          admin.firestore().collection("sessions");

          Sessions.where("audioUrl", ">=", "http")
              .get()
              .then((snapshots) => {
                if (snapshots.size > 0) {
                  snapshots.forEach((sessions) => {
                    Sessions.doc(sessions.id).update({
                      containsAudio: true,
                    });
                  });
                }
              });
          return Sessions;
        });
