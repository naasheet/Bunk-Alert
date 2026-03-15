const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendGroupAlert = functions.https.onCall(async (data, context) => {
  const groupId = data.groupId;
  const title = data.title || "Group Alert";
  const body = data.body || "New update in your study group.";

  if (!groupId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "groupId is required"
    );
  }

  const topic = `group_${groupId}`;
  const message = {
    topic,
    notification: { title, body },
    data: { type: "group_alert", groupId },
  };

  await admin.messaging().send(message);
  return { success: true };
});

exports.sendAttendanceWarning = functions.https.onCall(
  async (data, context) => {
    const userId = data.userId || (context.auth && context.auth.uid);
    const title = data.title || "Attendance Warning";
    const body =
      data.body || "Your attendance is near the threshold. Take action.";

    if (!userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId is required"
      );
    }

    const tokensSnapshot = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("fcm_tokens")
      .get();

    const tokens = tokensSnapshot.docs.map((doc) => doc.id);
    if (tokens.length === 0) {
      return { success: false, reason: "no_tokens" };
    }

    const message = {
      tokens,
      notification: { title, body },
      data: { type: "attendance_warning" },
    };

    await admin.messaging().sendEachForMulticast(message);
    return { success: true, count: tokens.length };
  }
);
