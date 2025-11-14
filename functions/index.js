const {onRequest} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Set the global options for all functions
setGlobalOptions({timeoutSeconds: 540, memory: "2GiB"});

/**
 * A function that adds categories to sessions with a specific mood ID.
 * This is an example of a modernized Cloud Function.
 * It uses the v2 API, async/await, and batch writes for efficiency.
 */
exports.addCategoriesToSessionsWithMood5 = onRequest(
    async (req, res) => {
        const sessionsRef = admin.firestore().collection("sessions");
        const moodId = 11;

        try {
            const snapshots = await sessionsRef.where("moodId", "==", moodId).get();

            if (snapshots.empty) {
                console.log(`No documents found with moodId: ${moodId}`);
                res.status(200).send(`No documents found with moodId: ${moodId}`);
                return;
            }

            const batch = admin.firestore().batch();
            snapshots.forEach(doc => {
                const docRef = sessionsRef.doc(doc.id);
                batch.update(docRef, {
                    category1: "life and living",
                    category2: "happy and blessed",
                    category3: "childhood and memory",
                    category4: "work and career",
                });
            });

            await batch.commit();

            const message = `Successfully updated ${snapshots.size} documents.`;
            console.log(message);
            res.status(200).send(message);
        } catch (error) {
            console.error("Error updating documents:", error);
            res.status(500).send("Internal Server Error");
        }
    });