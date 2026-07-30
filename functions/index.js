const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { RtcTokenBuilder, RtcRole } = require("agora-token");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// Your Agora credentials
const APP_ID = "b476113d691f42dcb7bc6882021afc9c";
const APP_CERTIFICATE = "207bc3f35f9f449089c5713b63e7f482";

exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const channelName = data.channelName;
  if (!channelName || typeof channelName !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      'The function must be called with "channelName".'
    );
  }

  // --- THE CRITICAL FIX IS HERE ---
  // Use the UID passed from the client if it exists and is a valid number.
  const uid = data.uid && typeof data.uid === 'number' ? data.uid : 0;
  // ---------------------------------

  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600; // 1 hour
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  try {
    console.log(`Generating token for channel: "${channelName}" with UID: ${uid}`);

    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uid, // Use the corrected UID
      role,
      privilegeExpiredTs
    );

    console.log(`Successfully generated token: ${token}`);
    return { token: token };

  } catch (error) {
    console.error("Error generating Agora token:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to generate Agora token."
    );
  }
});

// Use runWith to declare that this function needs access to the GEMINI_API_KEY secret
exports.moderateFeatureRequest = functions.runWith({ secrets: ["GEMINI_API_KEY"] }).https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { title, message, egoName, sessionMessage } = data;
  if (!title || !message) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      'The function must be called with "title" and "message".'
    );
  }

  // Access the secret from environment variables
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("GEMINI_API_KEY is not set in secrets.");
    return { isAbusive: false, error: "Configuration error" };
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
      systemInstruction: "You are a content moderator for 'Dear Claire', a secret diary app. " +
        "Analyze the user's feature request and the associated session content for abusive, illicit, or harmful content. " +
        "Answer with ONLY 'true' if it is harmful/abusive, or 'false' if it is safe.",
    });

    const prompt = `User's Feature Request:\nTitle: ${title}\nExplanation: ${message}\n\nSession Content to Feature:\n${sessionMessage || 'N/A'}\n\nSubmitted by: ${egoName}`;
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text().toLowerCase().trim();

    console.log(`Moderation result for ${egoName}: ${text}`);

    return { isAbusive: text === "true" };
  } catch (error) {
    console.error("Gemini Moderation Error:", error);
    // Safe fallback: if AI fails, allow the request but log the error
    return { isAbusive: false, error: "Moderation service unavailable" };
  }
});
