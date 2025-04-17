library(shiny)
library(shinydashboard)
library(shinyjs)
library(DT)
library(ggplot2)
library(mlbench)

# Load dataset
data(PimaIndiansDiabetes)
df <- PimaIndiansDiabetes  # Full dataset

unique(df)

addResourcePath("js", "jsfile")  # Ensure jsfile directory contains speak.js

#login credentials
valid_users <- reactiveValues(data = list("user1" = "password123", "admin" = "adminpass"))

sidebar <- dashboardSidebar(
  width = 250,  collapsed = TRUE, 
  sidebarMenu(
    id = "sidebar", 
    menuItem("Tab 2", tabName = "tab2", icon = icon("star")), 
    menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard"), selected = TRUE)
  )
)

tab2 <- tabItem(
  tabName = "tab2", 
  div(style = "text-align: center;", h2("Reminder")),
  textInput("reminder_time", "Set Time (HH:MM) in 24H Format", placeholder = "12:00"),
  textInput("reminder_message", "Reminder Message", placeholder = "Take Medicine"),
  actionButton("set_reminder", "Set Reminder"),
  actionButton("stop_reminder", "Stop Reminder"), 
  
  hr(), 
  
  #Display Table of reminders
  h3("All Reminders"),
  actionButton("remove_reminder", "Remove Reminder"), 
  hr(),
  DTOutput("reminder_table")
)

home <- tabItem(
  tabName = "dashboard", 
  div(style = "text-align: center;", h2("Dashboard")),
  
  # Voice Command Section
  box(
    title = "Voice Commands", status = "primary", solidHeader = TRUE, width = 12,
    tags$ul(
      tags$li("1. Go to Reminder Page"),
      tags$li("2. Set Reminder"),
      tags$li("3. Stop Reminder"),
      tags$li("4. Show All Reminders"),
      tags$li("5. Clear All Reminders")
    )
  ),
  
  # Space for Charts
  fluidRow(
    box(title = "Glucose Chart", status = "info", solidHeader = TRUE, width = 6, 
        plotOutput("glucose_plot", height = "250px")),  
    
    box(title = "Blood Pressure Chart", status = "warning", solidHeader = TRUE, width = 6, 
        plotOutput("pressure_plot", height = "250px"))
  ),
  
  fluidRow(
    box(title = "Heart Rate Chart", status = "danger", solidHeader = TRUE, width = 6, 
        plotOutput("heart_rate_plot", height = "250px")),
    
    box(title = "Sleep Duration Chart", status = "primary", solidHeader = TRUE, width = 6, 
        plotOutput("sleep_plot", height = "250px"))
  )
)


body <- dashboardBody(
  useShinyjs(),
  
  tags$head(
    tags$script(src = "js/speak.js"), 
    tags$script(src = "js/textRecognition.js"),
    tags$script(src = "js/chatbot.js")  # Ensure chatbot.js is loaded
  ),
  
  tabItems(
    home,
    tab2
  ), 
  
  tags$footer(
    div(
      style = "position: fixed; bottom: 0; left: 0; width: 100%; background-color: #333; color: white; text-align: center; padding: 10px;",
      actionButton("Home", "Home", icon = icon("home")),
      actionButton("Reminder", "Reminder", icon = icon("calendar")),
      actionButton("go_chatbot", "Chatbot", icon = icon("robot"), onclick = "window.open('https://cdn.botpress.cloud/webchat/v2.2/shareable.html?configUrl=https://files.bpcontent.cloud/2025/03/25/02/20250325023853-RLCMU0RQ.json','_blank','resizable,height=600,width=400')") # JavaScript event
    )
  )
)

header <- dashboardHeader(
  title = div(
    style = "display: flex; justify-content: space-between; align-items: center; width: 100%;",
    tags$span(style = "font-size: 24px; font-weight: bold;", "VitaCare"),
    actionButton("logout_btn", "Logout", icon = icon("sign-out-alt"), 
                 style = "margin-right: 10px; background-color: red; color: white; border: none; padding: 5px 15px; border-radius: 5px;")
  ),
  titleWidth = "100%"
)

dashboardUI <- dashboardPage(header, sidebar, body)

login <- fluidPage(
  useShinyjs(), # Enable JavaScript functions for hiding/showing UI
  tags$head(tags$style(
    HTML("
      #login-panel {
        max-width: 400px; 
        margin: auto; 
        padding: 20px; 
        border: 1px solid #ddd; 
        border-radius: 10px; 
        box-shadow: 2px 2px 10px rgba(0,0,0,0.1);
      }
      #login-status {
        color: red;
      }
    ")
  )),
  
  div(id = "login-panel", 
      h2("Login Page"),
      textInput("username", "Username"),
      passwordInput("password", "Password"),
      actionButton("login_btn", "Login"),
      actionButton("register_btn", "Register"),
      div(id = "login-status", "")  # Status message for wrong login
  )
)

register <- fluidPage(
  useShinyjs(),
  tags$head(tags$style(
    HTML("
      #register-panel {
        max-width: 400px; 
        margin: auto; 
        padding: 20px; 
        border: 1px solid #ddd; 
        border-radius: 10px; 
        box-shadow: 2px 2px 10px rgba(0,0,0,0.1);
        background-color: #f9f9f9;
      }
      #register-status {
        color: red;
        font-weight: bold;
      }
    ")
  )),
  
  div(id = "register-panel", 
      h2(style = "text-align: center;", "Register Page"), 
      
      textInput("userid", "User ID"),  # Unique identifier for each user
      textInput("name", "Full Name"),
      #dateInput("dob", "Date of Birth"),
      selectInput("gender", "Gender", choices = c("Male", "Female", "Other")),
      
      textInput("email", "Email"),
      passwordInput("register_password", "Password"),
      
      textInput("disease", "Diagnosed Disease"),
      textAreaInput("medicine", "Required Medications", 
                    placeholder = "List the medications you need"),
      
      actionButton("register_complete_btn", "Register", class = "btn-primary"),
      
      div(id = "register-status", "")  # Status message
  )
)

ui <- fluidPage(
  useShinyjs(),
  titlePanel("VitaCare"),
  hidden(div(id = "dashboard", dashboardUI)),
  hidden(div(id = "register-ui", register)),
  div(id = "login-ui", login)
)

# 🔹 Define `loginServer` Function
loginServer <- function(input, output, session, user) {
  observeEvent(input$login_btn, {
    username <- input$username
    password <- input$password
    
    # Correct access to `valid_users$data`
    if (username %in% names(valid_users$data) && valid_users$data[[username]] == password) {
      user$logged_in <- TRUE
      hide("login-ui")   # Hide login page
      show("dashboard")  # Show dashboard
    } else {
      updateTextInput(session, "password", value = "")  # Clear password
      shinyjs::html("login-status", "Invalid username or password!")
    }
  })
}

# register server
registerServer <- function(input, output, session) {
  observeEvent(input$register_complete_btn, {
    userid <- input$userid
    password <- input$register_password
    email <- input$email
    
    # Ensure user ID, password, and email are provided
    if (userid == "" || password == "" || email == "") {
      shinyjs::html("register-status", "User ID, Password, and Email cannot be empty!")
      return()
    }
    
    # Check if User ID already exists
    if (userid %in% names(valid_users$data)) {
      shinyjs::html("register-status", "User ID already exists! Choose another.")
      return()
    }
    
    # Email validation using regex
   # valid_email_pattern <- "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    #if (!grepl(valid_email_pattern, email)) {
    #  shinyjs::html("register-status", "Invalid email format! Please enter a valid email.")
    #  return()
   # }
    
    # Save new user credentials
    valid_users$data[[userid]] <- password
    print(valid_users$data) 
    
    # Show success message
    shinyjs::html("register-status", "Registration Successful! Redirecting to login...")
    
    # Delay and redirect to login page
    Sys.sleep(2)
    hide("register-panel")
    show("login-ui")
  })
}

# chart server
glucoseServer <- function(input, output, session) {
  library(dplyr)
  
  # Load dataset
  data(PimaIndiansDiabetes, package = "mlbench")
  
  # Add simulated sleep hours & heart rate
  dataset <- PimaIndiansDiabetes %>%
    mutate(
      SleepHours = runif(n(), min = 4, max = 9),  # Random sleep hours
      heart_rate = runif(n(), min = 60, max = 100) # Random heart rate
    )
  
  # Keep only the first 10 rows for plotting
  dataset <- dataset[1:10, ]
  
  # Plot Glucose
  output$glucose_plot <- renderPlot({
    ggplot(dataset, aes(x = 1:10, y = glucose)) +
      geom_line(color = "blue") +
      geom_point(color = "darkblue") +
      labs(title = "Glucose Levels", x = "Index", y = "Glucose") +
      theme_minimal()
  })
  
  # Plot Blood Pressure
  output$pressure_plot <- renderPlot({
    ggplot(dataset, aes(x = 1:10, y = pressure)) +
      geom_line(color = "red") +
      geom_point(color = "darkred") +
      labs(title = "Calories Record", x = "Index", y = "Pressure") +
      theme_minimal()
  })
  
  # Plot Heart Rate
  output$heart_rate_plot <- renderPlot({
    ggplot(dataset, aes(x = 1:10, y = heart_rate)) +
      geom_line(color = "green") +
      geom_point(color = "darkgreen") +
      labs(title = "Heart Rate", x = "Index", y = "Heart Rate (bpm)") +
      theme_minimal()
  })
  
  # Plot Sleep Duration
  output$sleep_plot <- renderPlot({
    ggplot(dataset, aes(x = 1:10, y = SleepHours)) +
      geom_line(color = "purple") +
      geom_point(color = "purple") +
      labs(title = "Stress", x = "Index", y = "Stress Level") +
      theme_minimal()
  })
}

server <- function(input, output, session) {
  
  user <- reactiveValues(logged_in = FALSE)
  
  # Call the `loginServer` function
  loginServer(input, output, session, user)
  
  # call the 'registerserver' function
  registerServer(input, output, session)
  
  observeEvent(user$logged_in, {
    if (user$logged_in) {  # Only run after login
      runjs("autoSpeak();")
      runjs("startRecognition();")
      
      observeEvent(reminders(), {
        # Get the latest reminders list
        reminder_data <- reminders()
        
        # Convert reminders data frame to a list
        reminder_list <- lapply(1:nrow(reminder_data), function(i) {
          list(index = i, time = reminder_data$Time[i], message = reminder_data$Message[i])
        })
        
        # Send reminders list to JavaScript
        session$sendCustomMessage("updateReminderList", reminder_list)
        session$sendCustomMessage("updateReminder", reminder_list)
      })
    }
  })
  
  #logout
  observeEvent(input$logout_btn, {
    hide("dashboard")   # Hide the dashboard
    show("login-ui")    # Show login page
    
    # Clear username and password inputs
    updateTextInput(session, "username", value = "")
    updateTextInput(session, "password", value = "")
    
    # Reset user login state
    user$logged_in <- FALSE
    
    # Run JavaScript to stop all active scripts
    runjs("
    window.speechSynthesis.cancel(); // Stop text-to-speech
    if (typeof recognition !== 'undefined') {
      stopRecognition(); // Stop voice recognition
    }
    if (typeof reminderInterval !== 'undefined') {
      clearInterval(reminderInterval); // Stop any reminder intervals
    }
  ")
  })
  
  observeEvent(input$register_btn, {
    hide("login-ui")       # Hide the login UI
    show("register-ui") # Show the register page
  })
  
  observeEvent(input$Reminder, {
    updateTabItems(session, "sidebar", "tab2")  # Navigate to Reminder tab
  })
  
  observeEvent(input$Home, {
    updateTabItems(session, "sidebar", "dashboard")
  })
  
  # Reactive data frame to store reminders
  reminders <- reactiveVal(data.frame(Time = character(), Message = character(), stringsAsFactors = FALSE))
  
  # When "Set Reminder" is clicked
  observeEvent(input$set_reminder, {
    time <- input$reminder_time
    message <- input$reminder_message
    
    # Validate input
    if (time == "" || message == "") {
      showNotification("Please enter both time and message!", type = "error")
      return()
    }
    
    # Append new reminder to data frame
    new_reminder <- data.frame(Time = time, Message = message, stringsAsFactors = FALSE)
    reminders(rbind(reminders(), new_reminder))  # Update reactive data
    
    # Send data to JavaScript for scheduling
    session$sendCustomMessage("scheduleReminder", list(time = time, message = message))
  })
  
  # Render the reminders table
  output$reminder_table <- renderDT({
    datatable(reminders(), options = list(pageLength = 5, autoWidth = TRUE))
  })
  
  observeEvent(input$stop_reminder, {
    
    # Ensure JavaScript function receives correct parameters
    runjs("stopTime()");  
  })
  
  # Remove Reminder
  observeEvent(input$remove_reminder, {
    selected_row <- input$reminder_table_rows_selected  # Get selected row index
    
    if (length(selected_row) == 0) {
      showNotification("Please select a reminder to remove!", type = "error")
      return()
    }
    
    # Extract selected reminder
    current_reminders <- reminders()
    removed_reminder <- current_reminders[selected_row, , drop = FALSE]
    
    # Remove from reactive list while keeping it as a data frame
    updated_reminders <- current_reminders[-selected_row, , drop = FALSE]
    if (nrow(updated_reminders) == 0) {
      updated_reminders <- data.frame(Time = character(), Message = character(), stringsAsFactors = FALSE)
    }
    reminders(updated_reminders)  # Update reactive list
    
    # Send only the removed reminder to JavaScript
    session$sendCustomMessage("updateReminderList", list(time = removed_reminder$Time[1], message = removed_reminder$Message[1]))
  })
  
  # Render Reminders Table (With Row Selection)
  output$reminder_table <- renderDT({
    datatable(
      reminders(), 
      options = list(pageLength = 5, autoWidth = TRUE),
      selection = "single"  # Allow selecting one row at a time
    )
  })
  
  # voice command
  observeEvent(input$voice_transcript, {
    print(paste("Received command:", input$voice_transcript))  # Debugging
    session$sendCustomMessage("handleVoiceCommand", input$voice_transcript)
  })
  
  # set reminder through voice
  observeEvent(input$reminder_data, {
    req(input$reminder_data$time, input$reminder_data$message)  # Ensure both exist
    
    reminder_info <- paste("Reminder set for", input$reminder_data$time, "with message:", input$reminder_data$message)
    
    showNotification(reminder_info, type = "message")  # Notify user in UI
    
    # Append new reminder to data frame
    new_reminder <- data.frame(Time = input$reminder_data$time, 
                               Message = input$reminder_data$message, 
                               stringsAsFactors = FALSE)
    reminders(rbind(reminders(), new_reminder))  # Update reactive data
    
    # Send data to JavaScript for scheduling
    session$sendCustomMessage("scheduleReminder", list(time = input$reminder_data$time, 
                                                       message = input$reminder_data$message))
  })
  
  # glucose server
  glucoseServer(input, output, session) 
}

shinyApp(ui = ui, server = server)
