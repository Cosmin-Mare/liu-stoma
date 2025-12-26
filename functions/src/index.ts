import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import twilio, { Twilio } from "twilio";
import { Timestamp, FieldValue } from "@google-cloud/firestore";

// Load .env file in local development (emulator)
if (process.env.FUNCTIONS_EMULATOR === "true" || process.env.NODE_ENV !== "production") {
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    require("dotenv").config();
  } catch (e) {
    // dotenv not installed, that's okay for production
  }
}

export const test = functions.https.onRequest((req, res) => {
  res.send("ok");
});


admin.initializeApp();

// Get Firestore instance to ensure it's initialized
const db = admin.firestore();

// Get Twilio credentials from environment variables (set via secrets)
function getTwilioClient() {
  const twilioAccountSid = process.env.TWILIO_ACCOUNT_SID;
  const twilioAuthToken = process.env.TWILIO_AUTH_TOKEN;

  if (!twilioAccountSid || !twilioAuthToken) {
    throw new Error(
      "Twilio credentials not configured. Set TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN secrets."
    );
  }

  return twilio(twilioAccountSid, twilioAuthToken);
}

interface Programare {
  programare_timestamp: Timestamp;
  programare_notification: boolean;
}

interface Patient {
  nume: string;
  telefon?: string;
  programari: Programare[];
}

/**
 * Core logic for checking appointments and sending notifications
 * Extracted to be reusable by both scheduled and HTTP functions
 */
async function checkAndSendAppointmentNotifications(): Promise<void> {
  const twilioClient = getTwilioClient();
  
  // Get current UTC time
  const nowUTC = new Date();
  
  // Get what time it is right now in Romania timezone
  const nowRomaniaStr = nowUTC.toLocaleString("en-US", {
    timeZone: "Europe/Bucharest",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
  
  // Parse Romania time components
  const [datePart, timePart] = nowRomaniaStr.split(", ");
  const [month, day, year] = datePart.split("/");
  const [hour, minute, second] = timePart.split(":");
  
  // Create a date representing current Romania time (as if it were UTC)
  // This is just for calculation purposes
  const nowRomaniaAsUTC = new Date(
    Date.UTC(
      parseInt(year),
      parseInt(month) - 1,
      parseInt(day),
      parseInt(hour),
      parseInt(minute),
      parseInt(second)
    )
  );
  
  // Calculate the offset: difference between actual UTC and Romania-time-as-UTC
  // This tells us how many milliseconds to adjust
  const offset = nowUTC.getTime() - nowRomaniaAsUTC.getTime();
  
  // Calculate 4 hours from now in Romania time
  const fourHoursFromNowRomania = new Date(nowRomaniaAsUTC.getTime() + 4 * 60 * 60 * 1000);
  
  // Convert back to actual UTC by adding the offset
  // This gives us the UTC timestamp that corresponds to "4 hours from now" in Romania time
  const fourHoursFromNowActualUTC = new Date(fourHoursFromNowRomania.getTime() + offset);
  
  // Convert to Firestore Timestamp for comparison
  const fourHoursFromNowUTC = Timestamp.fromDate(fourHoursFromNowActualUTC);

  // Allow a 15-minute window (since we check every 15 minutes)
  const windowStart = Timestamp.fromMillis(
    fourHoursFromNowUTC.toMillis() - 7.5 * 60 * 1000
  );
  const windowEnd = Timestamp.fromMillis(
    fourHoursFromNowUTC.toMillis() + 7.5 * 60 * 1000
  );

  // Log in Romania time for clarity
  const windowStartRomania = windowStart.toDate().toLocaleString("ro-RO", {
    timeZone: "Europe/Bucharest",
  });
  const windowEndRomania = windowEnd.toDate().toLocaleString("ro-RO", {
    timeZone: "Europe/Bucharest",
  });

  console.log(
    `Checking appointments between ${windowStartRomania} and ${windowEndRomania} (plm time)`
  );

  // Get all patients
  console.log("Getting all patients");
  const patientsSnapshot = await db.collection("patients").get();
  console.log(patientsSnapshot.docs.length);

      const notificationsToSend: Array<{
        patientId: string;
        patientName: string;
        phone: string;
        appointmentTime: Date;
        appointmentTimestamp: Timestamp;
      }> = [];
  // Check each patient's appointments
  for (const patientDoc of patientsSnapshot.docs) {
    const patientData = patientDoc.data() as Patient;
    const patientId = patientDoc.id;
    console.log(patientData.nume);
    console.log(patientData.programari);
    console.log("________________________________________________________");

    if (!patientData.programari || !Array.isArray(patientData.programari)) {
      continue;
    }

    // Check each appointment
    for (const programare of patientData.programari) {
      // Skip if notifications are disabled
      if (!programare.programare_notification) {
        continue;
      }

      const appointmentTime = programare.programare_timestamp;
      console.log(windowStart.toDate())
      console.log(windowEnd.toDate())
      console.log(appointmentTime.toDate());
      console.log(appointmentTime.toMillis() >= windowStart.toMillis());
      console.log(appointmentTime.toMillis() <= windowEnd.toMillis());



      // Check if appointment is within our 4-hour window
      if (
        appointmentTime.toMillis() >= windowStart.toMillis() &&
        appointmentTime.toMillis() <= windowEnd.toMillis()
      ) {
        // Check if we've already sent a notification for this appointment
        const notificationKey = `${patientId}_${appointmentTime.toMillis()}`;
        const notificationDoc = await admin
          .firestore()
          .collection("sent_notifications")
          .doc(notificationKey)
          .get();

        if (!notificationDoc.exists) {
          // Only send if patient has a phone number
          if (patientData.telefon && patientData.telefon.trim() !== "") {
            notificationsToSend.push({
              patientId: patientId,
              patientName: patientData.nume,
              phone: patientData.telefon,
              appointmentTime: appointmentTime.toDate(),
              appointmentTimestamp: appointmentTime,
            });
          }
        }
      }
    }
  }

  console.log(`Found ${notificationsToSend.length} notifications to send`);

  // Send notifications
  const results = await Promise.allSettled(
    notificationsToSend.map(async (notification) => {
      const phoneNumber = formatPhoneNumber(notification.phone);
      if (!phoneNumber) {
        throw new Error(`Invalid phone number: ${notification.phone}`);
      }

      const message = createMessage(
        notification.patientName,
        notification.appointmentTime
      );

      // Send SMS
      try {
        await sendSMS(twilioClient, phoneNumber, message);
        console.log(`SMS sent to ${phoneNumber}`);
      } catch (smsError) {
        console.error(`Failed to send SMS to ${phoneNumber}:`, smsError);
        throw smsError; // Re-throw SMS errors as they're critical
      }

      // Mark notification as sent (don't fail the whole operation if this fails)
      const notificationKey = `${notification.patientId}_${notification.appointmentTimestamp.toMillis()}`;
      try {
        await db.collection("sent_notifications").doc(notificationKey).set({
          sentAt: FieldValue.serverTimestamp(),
          patientId: notification.patientId,
          phone: phoneNumber,
          message: message,
          sentVia: "sms",
        });
        console.log(`Notification marked as sent in Firestore for ${phoneNumber}`);
      } catch (firestoreError) {
        // Log but don't throw - SMS was already sent successfully
        console.error(`Failed to mark notification as sent in Firestore for ${phoneNumber}:`, firestoreError);
        // Don't re-throw - SMS was sent successfully, Firestore write failure is non-critical
      }
    })
  );

  // Log results with details
  const successful = results.filter((r) => r.status === "fulfilled").length;
  const failed = results.filter((r) => r.status === "rejected").length;
  
  // Log details of failures
  results.forEach((result, index) => {
    if (result.status === "rejected") {
      console.error(`Notification ${index + 1} failed:`, result.reason);
    }
  });
  
  console.log(`Notifications sent: ${successful} successful, ${failed} failed`);
}

/**
 * Scheduled function that runs every 15 minutes to check for appointments
 * that are 4 hours away and send SMS notifications
 */
export const checkAppointments = functions
  .runWith({
    secrets: ["TWILIO_ACCOUNT_SID", "TWILIO_AUTH_TOKEN", "TWILIO_SMS_FROM"],
  })
  .pubsub.schedule("every 15 minutes")
  .timeZone("Europe/Bucharest")
  .onRun(async (_context) => {
    try {
      await checkAndSendAppointmentNotifications();
      return null;
    } catch (error) {
      console.error("Error checking appointments:", error);
      throw error;
    }
  });

/**
 * HTTP function for testing the appointment check logic locally
 * This makes it easier to test without dealing with Pub/Sub emulator issues
 */
export const testCheckAppointments = functions
  .runWith({
    secrets: ["TWILIO_ACCOUNT_SID", "TWILIO_AUTH_TOKEN", "TWILIO_SMS_FROM"],
  })
  .https.onRequest(async (req, res) => {
    try {
      await checkAndSendAppointmentNotifications();
      res.status(200).json({ success: true, message: "Appointment check completed" });
    } catch (error) {
      console.error("Error checking appointments:", error);
      res.status(500).json({ 
        success: false, 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  });

/**
 * Format phone number to E.164 format for Twilio
 */
function formatPhoneNumber(phone: string): string | null {
  // Remove all non-digit characters except +
  let cleaned = phone.replace(/[^\d+]/g, "");

  // If it starts with 0, replace with country code (Romania: +40)
  if (cleaned.startsWith("0")) {
    cleaned = "+40" + cleaned.substring(1);
  } else if (!cleaned.startsWith("+")) {
    // If no country code, assume Romania
    cleaned = "+40" + cleaned;
  }

  // Validate E.164 format (starts with +, followed by 1-15 digits)
  if (/^\+[1-9]\d{1,14}$/.test(cleaned)) {
    return cleaned;
  }

  return null;
}

/**
 * Create notification message
 */
function createMessage(
  patientName: string,
  appointmentTime: Date
): string {
  const timeStr = appointmentTime.toLocaleString("ro-RO", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    timeZone: "Europe/Bucharest",
  });

  return `Bună ${patientName}! Vă reamintim că aveți o programare pe data de ${timeStr}. Vă așteptăm!`;
}

/**
 * Send SMS via Twilio
 */
async function sendSMS(
  client: Twilio,
  phoneNumber: string,
  message: string,
): Promise<boolean> {
  try {
    const smsNumber = process.env.TWILIO_SMS_FROM;
    if (!smsNumber) {
      throw new Error("SMS number not configured. Set TWILIO_SMS_FROM secret.");
    }

    await client.messages.create({
      from: smsNumber,
      to: phoneNumber,
      body: message,
    });
  } catch (error) {
    console.error(`Failed to send SMS to ${phoneNumber}:`, error);
    return false;
  }

  return true;
}

