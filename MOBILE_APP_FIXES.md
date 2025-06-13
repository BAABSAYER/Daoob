# Mobile App Issues Analysis & Fixes

## Issues Identified

### 1. User Registration Not Recognized by Web Dashboard
**Problem**: Users registered via mobile app don't appear in web admin dashboard
**Root Cause**: Mobile app connects to production server while web dashboard may be on different environment

### 2. Questionnaire Questions Not Displaying
**Problem**: Event request form shows default design instead of dynamic questions
**Root Cause**: API endpoint mismatch - mobile app calls `/questions` but backend uses `/questionnaire-items`

### 3. Event Request Submission Failures  
**Problem**: Failed to submit event requests
**Root Cause**: Data structure mismatches between mobile app and backend expectations

## Applied Fixes

### Fix 1: Corrected API Endpoints
- Changed questionnaire endpoint from `/event-types/{id}/questions` to `/event-types/{id}/questionnaire-items`
- Updated User model to handle `fullName` field from backend

### Fix 2: Authentication Data Structure
- Fixed User.fromJson to properly parse backend response with `fullName` field
- Mobile app already uses session-based authentication via ApiService

### Fix 3: Event Submission Structure
- Event submission already correctly uses `/api/bookings` endpoint
- Proper transformation from mobile request data to backend booking structure

## Verification Steps

1. **Check Mobile App Environment Configuration**
2. **Test User Registration Flow**  
3. **Verify Questionnaire Loading**
4. **Test Event Request Submission**

## Production Server Status
- Event Types: 3 active (wedding, hi, xxxxx)
- Questionnaire Items: Available for event type 1
- API endpoints responding correctly