# Loggit Project Overview

This document outlines the phases, goals, and features of the Loggit app. Each phase includes a **detailed checklist**. Cursor can tick off tasks as they're completed.

## 📋 Feature Scope Documents

For detailed implementation plans of specific features, see:
- **Notes Feature**: `scope/NOTES_FEATURE_SCOPE.md` - Comprehensive notes system with AI integration
- **Chat NLP**: `scope/CHAT_NLP-SCOPE.MD` - Advanced natural language processing patterns

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
    - [x] **For comprehensive NLP patterns and smart responses, see: `scope/CHAT_NLP-SCOPE.MD`**

  - [x] Confirmation Prompts
    - [x] Display confirmation for:
      - [x] Tasks
      - [x] Reminders
      - [x] Notes
      - [x] Gym logs
    - [x] Implement Yes/No handling for each

  - [x] Dashboards for Each Log Type
    - [x] Task Dashboard (Tasks Page)
      - [x] Core Functions
        - [x] Create a Task
          - [x] Add task title
          - [x] Add optional description/notes
          - [x] Set due date & time
          - [x] Assign category (e.g. Work, Personal)
          - [x] Set priority level (High, Medium, Low)
        - [x] Edit / Update a Task
          - [x] Change title, description, or date
          - [x] Adjust priority or category
          - [x] Mark as recurring, if needed
        - [x] View Task List
          - [x] Filter by status (Pending, Completed)
          - [x] Filter by date (Today, This Week, etc.)
          - [x] Filter by category or priority
          - [x] Search tasks quickly
        - [x] Mark Task as Completed
          - [x] Simple checkbox or swipe gesture
          - [x] Option to undo if checked by mistake
        - [x] Delete a Task
          - [x] Single task deletion
          - [x] Option to delete multiple tasks at once
        - [ ] Reminders / Notifications
          - [ ] Push notifications for upcoming deadlines
          - [ ] Option to snooze reminders
        - [ ] Recurring Tasks
          - [ ] Daily, weekly, monthly repeats
          - [ ] Optional end date for repeating tasks
        - [ ] Notes / Attachments
          - [ ] Add a note or short comment to a task
          - [ ] Optionally attach files or images (advanced, Phase 2+)
        - [x] Sorting & Grouping
          - [x] Sort tasks by due date, priority, or category
          - [x] Group tasks under headers like Today, Tomorrow, Upcoming
        - [x] Dark Mode Support
          - [x] Ensure consistent look in dark theme
      - [ ] Optional (Nice-to-Have) Features
        - [ ] Progress indicator (for big tasks with subtasks)
        - [ ] Collaboration / Assign tasks to others (Phase 3+)
        - [ ] Voice input (speak your task instead of typing)
        - [ ] Calendar view (see tasks on a calendar grid)
      - [x] All features should integrate naturally with chat/text commands, e.g.:
        - [x] "Add task: Call accountant tomorrow at 3pm"
        - [x] "Show my tasks for this week"
        - [x] "Complete 'Submit VAT return'"
    - [x] Reminder Dashboard
      - [x] Show upcoming reminders
      - [x] Allow editing reminders
    - [ ] Notes Dashboard
      - [ ] **For comprehensive Notes feature scope, see: `scope/NOTES_FEATURE_SCOPE.md`**
      - [ ] Basic note creation and management
      - [ ] AI integration for note creation
      - [ ] Cross-feature integration with tasks and reminders
      - [ ] Advanced organization and search capabilities
    - [ ] Gym Log Dashboard
      - [ ] Summarize workouts
      - [ ] View logs by date

  - [x] Edit/Delete Capability
    - [x] Add edit function for each log type
    - [x] Add delete function for each log type

  - [x] Customizable Categories
    - [x] Allow user to create new categories
    - [x] Assign categories to logs
    - [x] Store custom categories

  - [x] Maintain Dark Mode Support
    - [x] Test all new screens in dark mode

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

  - [ ] Subscription Payments
    - [ ] Integrate Google Play billing
    - [ ] Integrate App Store billing
    - [ ] Offer monthly and yearly plans
    - [ ] Implement subscription status checks

  - [ ] Feature Gating
    - [ ] Lock premium features if subscription inactive
    - [ ] Show upgrade prompts for locked features

---

- [ ] **Phase 5: AI Learning & Local Intelligence**

  - [ ] AI Interaction Logging
    - [ ] Log all user inputs and AI responses
    - [ ] Store successful parsing patterns
    - [ ] Track user confirmation/feedback
    - [ ] Create learning database structure

  - [ ] Pattern Learning System
    - [ ] Extract common patterns from AI responses
    - [ ] Learn date/time format variations
    - [ ] Build intent classification patterns
    - [ ] Store learned patterns locally

  - [ ] Local Parser Evolution
    - [ ] Phase 1: Simple Pattern Learning
      - [ ] Extract basic patterns (dates, times, intents)
      - [ ] Build simple matching rules
      - [ ] Test with common cases
    - [ ] Phase 2: Structured Learning
      - [ ] Learn complex date formats ("27th of August")
      - [ ] Understand context and conversation flow
      - [ ] Build confidence scoring system
    - [ ] Phase 3: Advanced Learning
      - [ ] Implement machine learning model
      - [ ] Train on user-specific patterns
      - [ ] Handle edge cases and exceptions

  - [ ] Hybrid Processing System
    - [ ] Local parser handles routine cases
    - [ ] AI handles complex/unknown patterns
    - [ ] Seamless fallback between systems
    - [ ] Performance optimization for speed

  - [ ] User Privacy & Data Control
    - [ ] All learning data stays local
    - [ ] No sensitive data sent to external AI
    - [ ] User controls what gets learned
    - [ ] Option to reset learning data

  - [ ] Learning Analytics
    - [ ] Track learning progress
    - [ ] Show accuracy improvements
    - [ ] Display patterns learned
    - [ ] User feedback on learning quality

  - [ ] Future Benefits
    - [ ] Instant local processing for common tasks
    - [ ] Reduced API costs
    - [ ] Works offline for routine operations
    - [ ] Personalized to user's communication style
    - [ ] Continuous improvement over time

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
  - [x] Ability to edit or delete logs
  - [ ] Guest mode without login

---

- [ ] **Future Premium-Only Features**
  - [ ] All business tools
  - [ ] Unlimited logs and storage
  - [ ] Multi-business support
  - [ ] Receipt uploads
  - [ ] Advanced analytics
  - [ ] Exports and reports
