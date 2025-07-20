# Notes Feature Scope - Loggit

## Overview

The Notes feature will be a comprehensive note-taking system integrated with Loggit's AI-powered chat interface. It will support multiple note types, cross-feature integration with Tasks and Reminders, and advanced organization capabilities.

---

## Core Features

### 1. Note Types

#### 📝 Text Notes
- **Rich text formatting** (bold, italic, underline, lists)
- **Title and content** fields
- **Category and tags** organization
- **Color coding** for visual organization
- **Created/updated timestamps**

#### ✅ Checklist Notes
- **Checkable items** with completion status
- **Add/remove items** dynamically
- **Progress tracking** (X of Y completed)
- **Convert to task** functionality
- **Nested sub-items** support

#### 📷 Media Notes
- **Photo attachments** (camera or gallery)
- **Voice recordings** with transcription
- **Document scanning** (OCR support)
- **Drawing/sketching** capability
- **File attachments** (PDFs, documents)

#### 📊 Quick Notes
- **Minimal input** for fast capture
- **Auto-categorization** based on content
- **Smart suggestions** for tags
- **One-tap creation** from chat

#### 🔗 Linked Notes
- **Connect related notes** together
- **Graph view** showing relationships
- **Cross-references** between notes
- **Related notes suggestions**

### 2. Organization System

#### 📁 Categories
- **Default categories**: Personal, Work, Ideas, Shopping, Health, Travel
- **Custom categories** creation
- **Category color coding**
- **Category-based filtering**

#### 🏷️ Tags
- **Auto-suggested tags** based on content
- **Custom tag creation**
- **Tag-based filtering**
- **Tag statistics** (usage count)

#### 🎨 Visual Organization
- **Color coding** (6-8 color options)
- **Priority indicators** (high, medium, low)
- **Status indicators** (draft, final, archived)
- **Visual icons** for different note types

#### 📅 Time-based Organization
- **Date-based grouping** (Today, Yesterday, This Week, etc.)
- **Created date** tracking
- **Modified date** tracking
- **Due date** for time-sensitive notes

### 3. Search and Discovery

#### 🔍 Smart Search
- **Full-text search** across titles and content
- **Tag-based search**
- **Category-based search**
- **Date range search**
- **Advanced filters** (type, status, priority)

#### 📊 Search Results
- **Relevance scoring**
- **Preview snippets**
- **Quick actions** from search results
- **Search history**

---

## AI Integration

### 1. Natural Language Processing

#### Basic Note Creation
```
User: "Create a note about meeting with John tomorrow"
AI Response: {
  "intent": "create_note",
  "fields": {
    "title": "Meeting with John",
    "content": "Meeting scheduled for tomorrow",
    "category": "work",
    "tags": ["meeting", "john"]
  }
}
```

#### Smart Content Extraction
```
User: "Save this: Project kickoff meeting tomorrow at 2pm, need to prepare presentation"
AI Response: {
  "intent": "create_note",
  "fields": {
    "title": "Project Kickoff Meeting",
    "content": "Project kickoff meeting tomorrow at 2pm. Need to prepare presentation.",
    "category": "work",
    "tags": ["meeting", "project", "kickoff", "presentation"]
  }
}
```

#### Template Recognition
```
User: "Shopping list: milk, bread, eggs, cheese"
AI Response: {
  "intent": "create_note",
  "fields": {
    "title": "Shopping List",
    "type": "checklist",
    "items": ["milk", "bread", "eggs", "cheese"],
    "category": "personal",
    "tags": ["shopping", "grocery"]
  }
}
```

### 2. Cross-Feature Integration

#### Notes + Tasks Integration
```
User: "Meeting notes: Discussed Q4 planning. Need to prepare budget report by Friday"
AI Response: {
  "intent": "create_note_with_task",
  "fields": {
    "note": {
      "title": "Q4 Planning Meeting",
      "content": "Discussed Q4 planning. Need to prepare budget report by Friday",
      "category": "work",
      "tags": ["meeting", "planning"]
    },
    "task": {
      "title": "Prepare budget report",
      "dueDate": "2025-07-25",
      "category": "work",
      "priority": "high"
    }
  }
}
```

#### Notes + Reminders Integration
```
User: "Create note about doctor appointment and remind me 1 hour before"
AI Response: {
  "intent": "create_note_with_reminder",
  "fields": {
    "note": {
      "title": "Doctor Appointment",
      "content": "Appointment details and questions to ask",
      "category": "personal",
      "tags": ["health", "appointment"]
    },
    "reminder": {
      "title": "Doctor Appointment",
      "reminderTime": "2025-07-22 14:00",
      "advanceTiming": "1 hour before"
    }
  }
}
```

#### Multi-Intent Processing
```
User: "Project kickoff meeting tomorrow at 2pm, need to prepare presentation, remind me 30 minutes before"
AI Response: {
  "intent": "create_multiple",
  "fields": {
    "note": {
      "title": "Project Kickoff Meeting",
      "content": "Project kickoff meeting tomorrow at 2pm",
      "category": "work",
      "tags": ["meeting", "project", "kickoff"]
    },
    "task": {
      "title": "Prepare Project Presentation",
      "dueDate": "2025-07-22",
      "category": "work",
      "priority": "high"
    },
    "reminder": {
      "title": "Project Kickoff Meeting",
      "reminderTime": "2025-07-22 14:00",
      "advanceTiming": "30 minutes before"
    }
  }
}
```

### 3. Smart AI Features

#### Context-Aware Suggestions
- **Auto-categorization** based on content analysis
- **Smart tag suggestions** from content keywords
- **Related notes suggestions** based on content similarity
- **Template suggestions** based on input patterns

#### Content Enhancement
- **Auto-formatting** of dates, times, and numbers
- **Link detection** and auto-linking
- **Email/phone number** detection and formatting
- **Address detection** and mapping suggestions

---

## User Interface Design

### 1. Main Notes Page

```
┌─────────────────────────────────────┐
│ 📝 Notes                    [+ New] │
├─────────────────────────────────────┤
│ [All] [Personal] [Work] [Ideas]     │
├─────────────────────────────────────┤
│ 🔍 Search notes...                  │
├─────────────────────────────────────┤
│ 📝 Meeting Notes - John             │
│    Discussed Q4 planning...         │
│    📅 Today 2:30 PM                 │
│    🏷️ work, important              │
├─────────────────────────────────────┤
│ ✅ Grocery List                     │
│    [ ] Milk [ ] Bread [ ] Eggs      │
│    📅 Yesterday                     │
│    🏷️ personal                     │
├─────────────────────────────────────┤
│ 🖼️ Project Screenshot               │
│    UI mockup for new feature        │
│    📅 2 days ago                    │
│    🏷️ work, design                 │
└─────────────────────────────────────┘
```

### 2. Note Creation Modal

```
┌─────────────────────────────────────┐
│ New Note                            │
├─────────────────────────────────────┤
│ Title: [Meeting Notes - John]       │
├─────────────────────────────────────┤
│ Type: [📝 Text] [✅ Checklist] [📷 Media] │
├─────────────────────────────────────┤
│ Content:                            │
│ [Rich text editor with formatting]  │
│                                     │
│ • Discussed Q4 planning             │
│ • Need to follow up on budget       │
│ • Schedule next meeting             │
├─────────────────────────────────────┤
│ Category: [Personal] [Work] [Ideas] │
│ Tags: [work] [important] [follow-up]│
│ Color: 🟦 🟨 🟩 🟥 🟪 🟫          │
├─────────────────────────────────────┤
│ [Cancel] [Save Note]                │
└─────────────────────────────────────┘
```

### 3. Note Detail View

```
┌─────────────────────────────────────┐
│ 📝 Meeting Notes - John             │
│ 🏷️ work, important                 │
│ 📅 Today 2:30 PM                    │
├─────────────────────────────────────┤
│ Content:                            │
│                                     │
│ Discussed Q4 planning with John.    │
│ Key points:                         │
│ • Budget needs approval             │
│ • Timeline: 3 months                │
│ • Next meeting: Friday 3pm          │
│                                     │
│ [Edit] [Share] [Delete]             │
├─────────────────────────────────────┤
│ 🔗 Related Items:                   │
│ • Reminder: Meeting with John       │
│ • Task: Prepare budget report       │
└─────────────────────────────────────┘
```

---

## Technical Implementation

### 1. Data Models

#### Note Model
```dart
class Note {
  final String id;
  final String title;
  final String content;
  final NoteType type; // text, checklist, media, quick, linked
  final String category;
  final List<String> tags;
  final Color color;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<NoteItem>? checklistItems; // for checklist notes
  final List<String>? mediaUrls; // for media notes
  final List<String>? linkedNoteIds; // for linked notes
  final List<String>? relatedTaskIds; // cross-references
  final List<String>? relatedReminderIds; // cross-references
  final NoteStatus status; // draft, final, archived
  final NotePriority priority; // high, medium, low
}
```

#### Note Item Model (for checklists)
```dart
class NoteItem {
  final String id;
  final String text;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<NoteItem>? subItems; // nested items
}
```

### 2. AI Service Integration

#### Extend AI Service
```dart
// Add to AI examples in ai_service.dart
User: "Create a note about project ideas"
Response: {"intent": "create_note", "fields": {...}}

User: "Meeting notes: discussed budget"
Response: {"intent": "create_note", "fields": {...}}

User: "Shopping list: milk, bread"
Response: {"intent": "create_note", "fields": {...}}
```

#### Multi-Intent Processing
```dart
// Handle complex intents
"create_note_with_task"
"create_note_with_reminder"
"create_multiple"
```

### 3. Storage and Persistence

#### Local Storage
- **SQLite database** for notes and relationships
- **File system** for media attachments
- **Shared preferences** for user settings

#### Cloud Sync (Future)
- **Supabase integration** for cloud storage
- **Real-time sync** across devices
- **Conflict resolution** for offline changes

---

## Implementation Phases

### Phase 1: Core Notes System (Weeks 1-2)

#### ✅ Basic Note Creation
- [ ] Create Note model and database schema
- [ ] Implement basic text note creation
- [ ] Add title, content, category, tags fields
- [ ] Create note creation modal
- [ ] Implement note storage and retrieval

#### ✅ AI Integration - Basic
- [ ] Extend AI service with note examples
- [ ] Implement "create_note" intent handling
- [ ] Add note creation to chat flow
- [ ] Create confirmation messages for notes

#### ✅ Notes Dashboard
- [ ] Create main notes page
- [ ] Implement note list display
- [ ] Add basic filtering by category
- [ ] Implement note editing and deletion

### Phase 2: Enhanced Features (Weeks 3-4)

#### ✅ Advanced Note Types
- [ ] Implement checklist notes
- [ ] Add media note support (photos)
- [ ] Create quick notes functionality
- [ ] Implement note templates

#### ✅ Organization Features
- [ ] Add color coding system
- [ ] Implement tag management
- [ ] Add priority and status indicators
- [ ] Create advanced filtering options

#### ✅ Search and Discovery
- [ ] Implement full-text search
- [ ] Add tag-based search
- [ ] Create search results page
- [ ] Add search history

### Phase 3: Cross-Feature Integration (Weeks 5-6)

#### ✅ Notes + Tasks Integration
- [ ] Implement "create_note_with_task" intent
- [ ] Add task creation from notes
- [ ] Create cross-references between notes and tasks
- [ ] Add related items display

#### ✅ Notes + Reminders Integration
- [ ] Implement "create_note_with_reminder" intent
- [ ] Add reminder creation from notes
- [ ] Create cross-references between notes and reminders
- [ ] Add reminder integration in note detail view

#### ✅ Multi-Intent Processing
- [ ] Implement "create_multiple" intent handling
- [ ] Add complex workflow creation
- [ ] Create combined confirmation messages
- [ ] Add workflow templates

### Phase 4: Advanced Features (Weeks 7-8)

#### ✅ Media and Attachments
- [ ] Add voice recording support
- [ ] Implement document scanning (OCR)
- [ ] Add drawing/sketching capability
- [ ] Create file attachment support

#### ✅ Smart Features
- [ ] Implement auto-categorization
- [ ] Add smart tag suggestions
- [ ] Create content enhancement features
- [ ] Add template recognition

#### ✅ Linked Notes
- [ ] Implement note linking system
- [ ] Create graph view for note relationships
- [ ] Add related notes suggestions
- [ ] Create note connection visualization

### Phase 5: Polish and Optimization (Weeks 9-10)

#### ✅ Performance Optimization
- [ ] Optimize search performance
- [ ] Implement lazy loading for large note lists
- [ ] Add caching for frequently accessed notes
- [ ] Optimize media handling

#### ✅ User Experience
- [ ] Add keyboard shortcuts
- [ ] Implement drag-and-drop functionality
- [ ] Create note sharing features
- [ ] Add export/import functionality

#### ✅ Testing and Bug Fixes
- [ ] Comprehensive testing of all features
- [ ] Performance testing with large datasets
- [ ] User acceptance testing
- [ ] Bug fixes and refinements

---

## Success Metrics

### Functional Metrics
- [ ] All note types working correctly
- [ ] AI integration responding accurately
- [ ] Cross-feature integration functioning
- [ ] Search and filtering working properly
- [ ] Media attachments handling correctly

### Performance Metrics
- [ ] Note creation: < 2 seconds
- [ ] Search results: < 1 second
- [ ] Media upload: < 5 seconds
- [ ] App responsiveness: No lag during use

### User Experience Metrics
- [ ] Intuitive note creation flow
- [ ] Easy navigation between features
- [ ] Consistent design with existing app
- [ ] Smooth AI integration experience

---

## Dependencies

### Technical Dependencies
- [ ] Existing AI service infrastructure
- [ ] Current task and reminder systems
- [ ] Database schema extensions
- [ ] Media handling libraries

### Design Dependencies
- [ ] Consistent with current design system
- [ ] Dark mode support
- [ ] Responsive design for all screen sizes
- [ ] Accessibility compliance

---

## Risk Assessment

### Technical Risks
- **AI Integration Complexity**: Multi-intent processing may be complex
- **Media Storage**: Large files could impact performance
- **Cross-References**: Maintaining data consistency across features

### Mitigation Strategies
- **Phased Implementation**: Start simple, add complexity gradually
- **Performance Testing**: Regular testing with realistic data volumes
- **Data Validation**: Robust validation for cross-references

---

## Future Enhancements

### Advanced AI Features
- **Voice-to-text** for note creation
- **Smart summarization** of long notes
- **Content suggestions** based on context
- **Automatic categorization** improvements

### Collaboration Features
- **Note sharing** with other users
- **Collaborative editing** of notes
- **Comment system** for shared notes
- **Version history** for note changes

### Integration Expansions
- **Calendar integration** for time-sensitive notes
- **Email integration** for note creation from emails
- **Cloud storage** integration (Google Drive, Dropbox)
- **Third-party app** integrations

---

*This scope document should be referenced in the main PROJECT_SCOPE.md file under the Notes feature section.* 