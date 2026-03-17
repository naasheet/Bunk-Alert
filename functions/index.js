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

exports.joinGroupByInviteCode = functions.https.onCall(
  async (data, context) => {
    const uid = context.auth && context.auth.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Please sign in to join a group."
      );
    }

    const inviteCode = String(data && data.inviteCode ? data.inviteCode : "")
      .trim()
      .toUpperCase();
    if (!inviteCode) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "inviteCode is required."
      );
    }

    const groupRef = admin.firestore().collection("groups").doc(inviteCode);

    await admin.firestore().runTransaction(async (tx) => {
      const groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Invite code not found."
        );
      }
      const groupData = groupSnap.data() || {};
      const members = Array.isArray(groupData.members) ? groupData.members : [];
      if (!members.includes(uid)) {
        tx.update(groupRef, {
          members: admin.firestore.FieldValue.arrayUnion(uid),
        });
      }
    });

    const updatedSnap = await groupRef.get();
    const updatedData = updatedSnap.data() || {};
    return {
      groupId: updatedSnap.id,
      ...updatedData,
    };
  }
);
