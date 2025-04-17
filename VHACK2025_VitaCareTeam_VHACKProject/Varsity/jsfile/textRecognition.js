var awaitingTime = false;
var awaitingMessage = false;
var reminderTime = "";
var reminderMessage = "";
var removeAwaitingTime = false;
var reminderList = [];
var messageList = [];
var recognitionStoppedManually = false;

Shiny.addCustomMessageHandler("updateReminder", function(data) {
    console.log("Reminder to remove:", data.time, data.message);
    
    if (reminderList.includes(data.time)) {
        let index = reminderList.indexOf(data.time);
        if (index !== -1) {
            console.log("Removing reminder for", data.time);

            reminderList.splice(index, 1);
            messageList.splice(index, 1);
            
            console.log("Updated Reminder List after removal:", reminderList);

            // Stop interval if no reminders are left
            if (reminderList.length === 0) {
                clearInterval(reminderInterval);
                reminderInterval = null;
                console.log("No more reminders. Stopping interval.");
                return; // Exit function early
            }
        }
    } else {
        console.log("Reminder not found:", data.time);
    }

    console.log("Updated JavaScript Reminder List:", reminderList);

    // Restart interval only if reminders exist
    if (reminderInterval === null) {
        reminderInterval = setInterval(checkTime, 1000);
        console.log("Reminder interval restarted.");
    }
});

function autoSpeak() {
    window.speechSynthesis.cancel();  // Stop any ongoing speech
    var msg = new SpeechSynthesisUtterance("Welcome to your dashboard. Say 'Voice Command' to hear all available voice commands.");
    msg.rate = 1;
    msg.pitch = 1;
    msg.volume = 1;
    msg.lang = "en-US";
    
    window.speechSynthesis.speak(msg);
}

function startRecognition() {
    if (!('webkitSpeechRecognition' in window)) {
        console.log("Speech recognition not supported.");
        return;
    }

    // Create a global recognition object if not already defined.
    if (typeof recognition === "undefined") {
        recognition = new webkitSpeechRecognition();
        recognition.continuous = true;
        recognition.interimResults = false;
        recognition.lang = "en-US";

        recognition.onresult = function (event) {
            var lastResultIndex = event.results.length - 1;
            var transcript = event.results[lastResultIndex][0].transcript.trim().toLowerCase();

            console.log("Recognized:", transcript);

            if (awaitingTime) {
                processReminderTime(transcript);
            } else if (awaitingMessage) {
                processReminderMessage(transcript);
            } else {
                // Send command to Shiny
                Shiny.setInputValue("voice_transcript", transcript, { priority: "event" });
            }
            
            if (removeAwaitingTime) {
                console.log("Recognition stopped");
                recognition.stop();
            }
        };

        recognition.onerror = function (event) {
            console.error("Speech recognition error:", event.error);
        };

        recognition.onend = function () {
            if (!recognitionStoppedManually) { // Only restart if not manually stopped
                console.log("Speech recognition stopped. Restarting in 1 second...");
                setTimeout(() => recognition.start(), 1000);
            }
        };
    }
    
    recognitionStoppedManually = false;
    recognition.start();
    console.log("Speech recognition started.");
}

function stopRecognition() {
    if (recognition) {
        recognitionStoppedManually = true; // Set flag to prevent restart
        recognition.stop();
        console.log("Speech recognition manually stopped.");
    }
}

// 🔹 Listen for messages from Shiny
Shiny.addCustomMessageHandler("handleVoiceCommand", function (command) {
    switch (command) {
        case "voice command":
            notifyUser("Available commands: Set Reminder, Stop Reminder, Show All Reminders and Clear All Reminders");
            break;
        case "set reminder":
            handleSetReminder();
            break;
        default:
            console.log("Unknown command:", command);
    }
});


// 🔹 Function to start the "Set Reminder" process
function handleSetReminder() {
    notifyUser("What time should I set the reminder?");
    awaitingTime = true; // Set flag to expect a time input next
}

// 🔹 Function to process the reminder time
function processReminderTime(timeInput) {
    reminderTime = convertTo24HourFormat(timeInput); // Convert to 24-hour format
    awaitingTime = false;
    awaitingMessage = true; // Now wait for the message input

    notifyUser("What is the reminder message?");
}

// 🔹 Function to process the reminder message
function processReminderMessage(messageInput) {
    reminderMessage = messageInput;
    awaitingMessage = false; // Reset flags

    // ✅ Send both time and message in a single event
    Shiny.setInputValue("reminder_data", 
        { time: reminderTime, message: reminderMessage }, 
        { priority: "event" }
    );

    notifyUser("Reminder set successfully for " + reminderTime + ".");
}


function convertTo24HourFormat(time) {
    var timeParts = time.match(/(\d{1,2}):?(\d{0,2})\s*(a.m.|p.m.)?/i);
    if (!timeParts) return time; // Return original if no match

    var hours = parseInt(timeParts[1], 10);
    var minutes = timeParts[2] ? parseInt(timeParts[2], 10) : 0;
    var period = timeParts[3] ? timeParts[3].toLowerCase() : null;

    if (period === "p.m." && hours < 12) {
        hours += 12;
    } else if (period === "a.m." && hours === 12) {
        hours = 0;
    }

    return hours.toString().padStart(2, "0") + ":" + minutes.toString().padStart(2, "0");
}

function notifyUser(message) {
    var msg = new SpeechSynthesisUtterance(message);
    msg.rate = 1;
    msg.pitch = 1;
    msg.volume = 1;
    msg.lang = "en-US";

    window.speechSynthesis.speak(msg);
    console.log("Voice Notification:", message);
}

