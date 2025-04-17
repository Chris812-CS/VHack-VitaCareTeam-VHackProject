var reminderInterval = null; 
var reminderList = [];
var messageList = [];

function speakMessage(message) {
    var msg = new SpeechSynthesisUtterance(message);
    msg.rate = 1;  
    msg.pitch = 1; 
    msg.volume = 1; 
    msg.lang = "en-US"; 

    window.speechSynthesis.speak(msg);

    msg.onend = function() {
        console.log("Speech completed.");
    };
    
    console.log("Reminder List: ", reminderList);
}

Shiny.addCustomMessageHandler("updateReminderList", function(data) {
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


// Receive data from Shiny and start checking time
Shiny.addCustomMessageHandler("scheduleReminder", function(data) {
    console.log("Reminder set for:", data.time, "Message:", data.message);
    
    if (!reminderList.includes(data.time)) {  
        reminderList.push(data.time);
        messageList.push(data.message);
        console.log("Updated Reminder List:", reminderList);
    }
  
    startCheckingTime(); // Ensure the interval is running
});

// Function to check the current time and trigger the voice message
/*function checkTime() {
    var now = new Date();
    var currentTime = now.getHours().toString().padStart(2, '0') + ":" + 
                      now.getMinutes().toString().padStart(2, '0');
    
    console.log("Current Time:", currentTime);

    let index = reminderList.indexOf(currentTime);
    if (index !== -1) {
        console.log("Reminder triggered for", currentTime);
        let message = messageList[index];
        repeatOption(currentTime, message);
    }
}*/

function checkTime() {
    var now = new Date();
    var currentTime = now.getHours().toString().padStart(2, '0') + ":" + 
                      now.getMinutes().toString().padStart(2, '0');
    
    console.log("Current Time:", currentTime);

    let index = reminderList.indexOf(currentTime);
    if (index !== -1) {
        console.log("Reminder triggered for", currentTime);
        let message = messageList[index];

        speakMessage(message);

        // Remove reminder after speaking to prevent repetition
        reminderList.splice(index, 1);
        messageList.splice(index, 1);
        console.log("Reminder removed after being spoken:", currentTime);

        // Stop interval if no reminders remain
        if (reminderList.length === 0) {
            clearInterval(reminderInterval);
            reminderInterval = null;
            console.log("No more reminders. Stopping interval.");
        }
    }
}

// Function to start the checking interval (if not already running)
function startCheckingTime() {
    if (reminderInterval === null) {
        reminderInterval = setInterval(checkTime, 1000);
        console.log("Reminder Interval Started.");
    }
}

// Function to stop and reschedule a reminder
function stopTime() {
    var now = new Date();
    var currentTime = now.getHours().toString().padStart(2, '0') + ":" + 
                      now.getMinutes().toString().padStart(2, '0');
                      
    console.log("Stopping reminder for:", currentTime);

    let index = reminderList.indexOf(currentTime);
    if (index !== -1) {
        let removedTime = reminderList[index];
        let removedMessage = messageList[index]; 

        reminderList.splice(index, 1);
        messageList.splice(index, 1);

        console.log("Updated Reminder List after removal:", reminderList);

        // Stop interval only if no reminders are left
        if (reminderList.length === 0) {
            clearInterval(reminderInterval);
            reminderInterval = null;
            console.log("No more reminders. Stopping interval.");
        }

        // Re-add the reminder after 1 minute
        setTimeout(function() {
            if (!reminderList.includes(removedTime)) {
                reminderList.push(removedTime);
                messageList.push(removedMessage);
                console.log("Reminder re-added:", removedTime);
                console.log("Updated Reminder List:", reminderList);

                startCheckingTime(); // Restart interval if stopped
            }
        }, 60000);
    }
}

// Manages repeating reminder logic
function repeatOption(time, message) {
    speakMessage(message);
}

function openChatbot() {
    window.open(
        "https://cdn.botpress.cloud/webchat/v2.2/shareable.html?configUrl=https://files.bpcontent.cloud/2025/03/25/02/20250325023853-RLCMU0RQ.json",
        "Chatbot",
        "width=400,height=600"
    );
}

