const functions = require("firebase-functions");
// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");

admin.initializeApp(functions.config().firebase);


const runtimeOpts = {
  timeoutSeconds: 540,
  memory: "2GB",
};

exports.addCategoriesToSessionsWithMood5 = functions.runWith(runtimeOpts)
    .https.onRequest(
        (req, res) => {
          const Sessions = admin.firestore().collection("sessions");

          Sessions.where("moodId", "==", 11)
              .get()
              .then((snapshots) => {
                if (snapshots.size > 0) {
                  snapshots.forEach((session) => {
                    Sessions.doc(session.id).update({
                      category1: "life and living",
                      category2: "happy and blessed",
                      category3: "childhood and memory",
                      category4: "work and career",
                    });
                  });
                }
              });
          return Sessions;
        });
