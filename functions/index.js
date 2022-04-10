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
          const Activities =
          admin.firestore().collection("user_activity");

          Activities.where("clientId", "==", "fSMVS2DY8ngblW3LlUYowgPkdR83")
              .get()
              .then((snapshots) => {
                if (snapshots.size > 0) {
                  snapshots.forEach((activity) => {
                    Activities.doc(activity.id).update({
                      clientId: "PbRuh3FmtESK57j3PM1Tc9RvPKh2",
                    });
                  });
                }
              });
          return Activities;
        });
