# Loggit Project Overview

This document outlines the phases, goals, and features of the Loggit app. Each phase includes a **detailed checklist**. Cursor can tick off tasks as they're completed.

---

## Phases and Features

---

- [x] **Phase 1: Expenses MVP**

  - [x] Project Setup
    - [x] Initialize Flutter project
    - [x] Configure pubspec.yaml
    - [x] Add required dependencies
    - [x] Set up folder structure
      - [x] /lib
      - [x] /lib/features
      - [x] /lib/models
      - [x] /lib/services
      - [x] /assets

  - [x] Implement Chat UI
    - [x] Create chat input widget
    - [x] Create chat bubble widget
    - [x] Display user messages in chat
    - [x] Display app response messages in chat
    - [x] Handle scrolling in chat window

  - [x] Parse Messages for Expenses
    - [x] Create regex pattern to extract:
      - [x] Expense amount (e.g. £3.50)
      - [x] Expense category/name (e.g. Coffee)
    - [x] Write parser service
    - [x] Test parsing with different messages

  - [x] Add Confirmation Prompt
    - [x] Show confirmation message:
      - [x] Example: "Log expense: £3.50 for Coffee? Yes/No"
    - [x] Implement Yes/No buttons
    - [x] Handle user response:
      - [x] Save expense if Yes
      - [x] Cancel if No

  - [x] Expense Storage
    - [x] Create Expense model:
      - [x] Category
      - [x] Amount
      - [x] Date/time
    - [x] Implement local storage:
      - [x] Save expenses locally
      - [x] Load expenses on app start
    - [ ] Optionally integrate Supabase:
      - [ ] Create expenses table in Supabase
      - [ ] Connect Flutter to Supabase
      - [ ] Save expenses to Supabase

  - [x] Dashboard
    - [x] Create dashboard screen
    - [x] Display total spent
    - [x] Display recent expenses list
      - [x] Add date and category display
    - [x] Design simple, non-overwhelming layout
    - [x] Ensure responsiveness for various devices

  - [x] Dark Mode Support
    - [x] Implement theme switching
    - [x] Test all screens in dark mode

  - [ ] Optional Features
    - [ ] Create pie chart widget
      - [ ] Show expenses by category
      - [ ] Integrate chart into dashboard

---

- [ ] **Phase 2: Multi-Log MVP**

  - [x] Add Log Types
    - [x] Define models for:
      - [x] Task
      - [x] Reminder
      - [x] Note
      - [x] Gym log
    - [x] Set up folder structure for each log type
    - [x] Create services for managing each log

  - [x] Chat-Driven Input
    - [x] Create regex/parsers for:
      - [x] Tasks (e.g. "Finish report tomorrow")
      - [x] Reminders (e.g. "Remind me to call client tomorrow.")
      - [x] Notes (e.g. "Note: Client prefers phone calls.")
      - [x] Gym logs (e.g. "Squats 3 sets x 10 reps.")
    - [x] Test parsing for edge cases

  - [x] Confirmation Prompts
    - [x] Display confirmation for:
      - [x] Tasks
      - [x] Reminders
      - [x] Notes
      - [x] Gym logs
    - [x] Implement Yes/No handling for each

  - [ ] Dashboards for Each Log Type
    - [ ] Task Dashboard (Tasks Page)
      - [ ] Core Functions
        - [ ] Create a Task
          - [ ] Add task title
          - [ ] Add optional description/notes
          - [ ] Set due date & time
          - [ ] Assign category (e.g. Work, Personal)
          - [ ] Set priority level (High, Medium, Low)
        - [ ] Edit / Update a Task
          - [ ] Change title, description, or date
          - [ ] Adjust priority or category
          - [ ] Mark as recurring, if needed
        - [ ] View Task List
          - [ ] Filter by status (Pending, Completed)
          - [ ] Filter by date (Today, This Week, etc.)
          - [ ] Filter by category or priority
          - [ ] Search tasks quickly
        - [ ] Mark Task as Completed
          - [ ] Simple checkbox or swipe gesture
          - [ ] Option to undo if checked by mistake
        - [ ] Delete a Task
          - [ ] Single task deletion
          - [ ] Option to delete multiple tasks at once
        - [ ] Reminders / Notifications
          - [ ] Push notifications for upcoming deadlines
          - [ ] Option to snooze reminders
        - [ ] Recurring Tasks
          - [ ] Daily, weekly, monthly repeats
          - [ ] Optional end date for repeating tasks
        - [ ] Notes / Attachments
          - [ ] Add a note or short comment to a task
          - [ ] Optionally attach files or images (advanced, Phase 2+)
        - [ ] Sorting & Grouping
          - [ ] Sort tasks by due date, priority, or category
          - [ ] Group tasks under headers like Today, Tomorrow, Upcoming
        - [ ] Dark Mode Support
          - [ ] Ensure consistent look in dark theme
      - [ ] Optional (Nice-to-Have) Features
        - [ ] Progress indicator (for big tasks with subtasks)
        - [ ] Collaboration / Assign tasks to others (Phase 3+)
        - [ ] Voice input (speak your task instead of typing)
        - [ ] Calendar view (see tasks on a calendar grid)
      - [ ] All features should integrate naturally with chat/text commands, e.g.:
        - [ ] “Add task: Call accountant tomorrow at 3pm”
        - [ ] “Show my tasks for this week”
        - [ ] “Complete ‘Submit VAT return’”
    - [ ] Reminder Dashboard
      - [ ] Show upcoming reminders
      - [ ] Allow editing reminders
    - [ ] Notes Dashboard
      - [ ] List notes
      - [ ] Edit or delete notes
    - [ ] Gym Log Dashboard
      - [ ] Summarize workouts
      - [ ] View logs by date

  - [ ] Edit/Delete Capability
    - [ ] Add edit function for each log type
    - [ ] Add delete function for each log type

  - [ ] Customizable Categories
    - [ ] Allow user to create new categories
    - [ ] Assign categories to logs
    - [ ] Store custom categories

  - [ ] Maintain Dark Mode Support
    - [ ] Test all new screens in dark mode

---

- [ ] **Phase 3: Business Features (Premium)**

  - [ ] Business Mode
    - [ ] Build toggle to switch between:
      - [ ] Personal logs
      - [ ] Business logs
    - [ ] Store separate logs for each mode

  - [ ] Multi-Business Profiles
    - [ ] Allow user to add multiple business profiles
    - [ ] Display business names
    - [ ] Link logs to selected business profile

  - [ ] Business Expense Logging
    - [ ] Add business-specific categories
    - [ ] Add tax categorization field to expense model
    - [ ] Display tax-related data on dashboard
    - [ ] Build Profit & Loss reports
    - [ ] Implement CSV/PDF export for business reports

  - [ ] Receipt Storage
    - [ ] Implement receipt upload:
      - [ ] Capture photo or select from gallery
      - [ ] Upload PDFs
    - [ ] Link receipts to expenses
    - [ ] Create receipts dashboard:
      - [ ] Filter by category/date/client

  - [ ] Multi-Currency Support
    - [ ] Add currency selector when logging expense
    - [ ] Implement conversion to home currency
    - [ ] Display converted totals on dashboard

  - [ ] Dashboard Widgets for Business
    - [ ] Profit/Loss summary widget
    - [ ] Tax estimate widget
    - [ ] Unpaid invoices widget (if invoicing is added)

  - [ ] Security Enhancements
    - [ ] Add PIN lock screen
    - [ ] Implement biometric unlock
    - [ ] Test security flows

---

- [ ] **Phase 4: Freemium & Subscriptions**

  - [ ] Free User Limits
    - [ ] Limit logs to certain number
    - [ ] Limit receipt storage
    - [ ] Disable business features
    - [ ] Limit Supabase storage for free users

  - [ ] Premium User Features
    - [ ] Remove all limits
    - [ ] Enable business mode
    - [ ] Enable receipt uploads
    - [ ] Provide full reports and exports
    - [ ] Enable multi-device sync
    - [ ] Allow multiple business profiles
    - [ ] Unlock AI analytics when available

  - [ ] Subscription Payments
    - [ ] Integrate Google Play billing
    - [ ] Integrate App Store billing
    - [ ] Offer monthly and yearly plans
    - [ ] Implement subscription status checks

  - [ ] Feature Gating
    - [ ] Lock premium features if subscription inactive
    - [ ] Show upgrade prompts for locked features

---

- [ ] **Phase 5: AI & Smart Analytics**

  - [ ] Natural-Language Summaries
    - [ ] Generate summaries like:
      ```
      This month, you spent £120 on dining out, 30% more than last month.
      ```
    - [ ] Display summaries in dashboard

  - [ ] Smart Suggestions
    - [ ] Auto-categorize expenses
    - [ ] Suggest cost-saving opportunities
    - [ ] Provide tax reminders for business logs

  - [ ] Predictive Analytics
    - [ ] Create cash flow projection charts
    - [ ] Identify spending trends

  - [ ] Conversational Q&A
    - [ ] Accept questions like:
      ```
      How much did I spend on groceries last month?
      ```
    - [ ] Fetch and display accurate answers

  - [ ] Future Integrations
    - [ ] OpenAI API integration
    - [ ] Supabase Edge Functions with AI
    - [ ] Explore local on-device AI for privacy

---

- [ ] **Across All Phases**
  - [x] Maintain dark mode support
  - [ ] Implement data export/restore:
      - [ ] JSON
      - [ ] CSV
      - [ ] PDF
      - [ ] Receipts as ZIP archive
  - [ ] Ensure secure cloud storage via Supabase
  - [ ] Provide local app security:
      - [ ] PIN lock
      - [ ] Biometric unlock

---

- [x] **MVP (Phase 1) Deliverables**
  - [x] Flutter mobile app
  - [x] Chat UI for expenses
  - [x] Expense parsing
  - [x] Confirmation prompts
  - [x] Local or Supabase saving of expenses
  - [x] Basic dashboard with totals
  - [x] Dark mode support
  - [ ] Ability to edit or delete logs
  - [ ] Guest mode without login

---

- [ ] **Future Premium-Only Features**
  - [ ] All business tools
  - [ ] Unlimited logs and storage
  - [ ] Multi-business support
  - [ ] Receipt uploads
  - [ ] Advanced analytics
  - [ ] Exports and reports
  - [ ] AI insights
