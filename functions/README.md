# Appointment Notification Functions

This Firebase Cloud Function sends SMS reminders 4 hours before appointments.

## Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Twilio

1. Sign up for a Twilio account at https://www.twilio.com/
2. Get your Account SID and Auth Token from the Twilio Console (Dashboard)
3. Get a phone number for SMS:
   - Go to Phone Numbers → Manage → Buy a number
   - Choose a number that supports SMS
   - Copy the number (e.g., `+1234567890`)
   - **Note:** You need a Twilio phone number - you cannot use your personal phone number with Twilio's API

### 3. Set Environment Variables

Set your Twilio credentials as secrets (modern approach, replaces deprecated `functions.config()`):

```bash
firebase functions:secrets:set TWILIO_ACCOUNT_SID
firebase functions:secrets:set TWILIO_AUTH_TOKEN
firebase functions:secrets:set TWILIO_SMS_FROM
```

When prompted, enter:
- `TWILIO_ACCOUNT_SID`: Your Twilio Account SID (from Dashboard)
- `TWILIO_AUTH_TOKEN`: Your Twilio Auth Token (from Dashboard)
- `TWILIO_SMS_FROM`: Your Twilio phone number (e.g., `+1234567890`)

**Note:** For local development with the emulator, create a `.secret.local` file in the `functions` directory (see "Testing Locally" section below).

### 4. Build and Deploy

```bash
npm run build
firebase deploy --only functions
```

## How It Works

- Runs every 15 minutes
- Checks all patients' appointments
- Finds appointments that are 4 hours away (±7.5 minutes window)
- Only sends if `programare_notification` is `true`
- Sends SMS via Twilio
- Tracks sent notifications in `sent_notifications` collection to avoid duplicates
- Uses Romania timezone (Europe/Bucharest)

## Testing Locally

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Create `.secret.local` file

The Firebase emulator needs a `.secret.local` file to provide secret values locally (the emulator can't access Google Cloud Secret Manager). Create this file in the `functions` directory:

```bash
cd functions
touch .secret.local
```

Add your credentials to `.secret.local` (dotenv format, one per line):
```
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_SMS_FROM=+1234567890
```

**Important:** 
- Make sure `.secret.local` is in your `.gitignore` (already added)
- This file is only used by the emulator for local testing
- For production, secrets are managed via `firebase functions:secrets:set`

### 3. Configure Firebase Emulator

The emulator configuration is already set up in `firebase.json`. It includes:
- Functions emulator on port 5001
- Pub/Sub emulator on port 8085 (required for scheduled functions)
- Emulator UI on port 4000

### 4. Start the Emulator

From the project root directory:

```bash
npm run serve
# or
cd functions && npm run serve
```

This will:
- Build the TypeScript code
- Start the Firebase Functions emulator on port 5001
- Start the Pub/Sub emulator on port 8085 (required for scheduled functions)
- Start the Emulator UI on port 4000

### 5. Trigger the Function Manually

For local testing, use the **HTTP test function** which is much easier:

**Option A: Use the HTTP Test Function (Recommended for Local Testing)**
```bash
curl http://localhost:5001/liu-stoma/us-central1/testCheckAppointments
```

Or open in your browser:
```
http://localhost:5001/liu-stoma/us-central1/testCheckAppointments
```

**Option B: Use the Emulator UI**
1. Open http://localhost:4000 in your browser
2. Go to the Functions tab
3. Find `testCheckAppointments` (HTTP function) and click "Trigger"
4. The function will execute and you'll see logs in the UI

**Option C: Use Firebase CLI Shell (for scheduled function)**
```bash
firebase functions:shell
# Then in the shell:
checkAppointments()
```

**Note:** 
- The `testCheckAppointments` HTTP function is only for local testing and calls the same logic as the scheduled function
- The scheduled function `checkAppointments` requires the Pub/Sub emulator and is harder to test locally
- For production, only the scheduled function will be deployed (you can exclude the test function from deployment)

### 6. View Logs

Logs will appear in the terminal where you ran `npm run serve`, or in the Emulator UI under the Logs tab.

**Note:** The emulator will use your local Firestore data if you have the Firestore emulator running, or it will connect to your production Firestore if not. To test with local data, also start the Firestore emulator.

## Monitoring

View logs:
```bash
firebase functions:log
```

View specific function logs:
```bash
firebase functions:log --only checkAppointments
```

## Cost

- Firebase Functions: Free tier includes 2M invocations/month (checking every 15 min = ~2,880/month)
- Twilio: 
  - Phone number: ~$1-2/month
  - SMS: ~$0.0075 per message (varies by country)
  - Trial account: Free credits to start

