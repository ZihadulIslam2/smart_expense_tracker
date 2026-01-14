#!/bin/bash

# 🎯 Steps 1-5 Implementation Verification Script
# Smart Expense Tracker

echo "================================================"
echo "🎯 Steps 1-5 - Implementation Verification"
echo "================================================"
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Function to check file
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $2"
        echo -e "${YELLOW}  Missing: $1${NC}"
        ((FAILED++))
    fi
}

# Function to check directory
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $2"
        echo -e "${YELLOW}  Missing: $1${NC}"
        ((FAILED++))
    fi
}

# Function to check dependency
check_dependency() {
    if grep -q "$1" pubspec.yaml; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $2"
        echo -e "${YELLOW}  Missing dependency: $1${NC}"
        ((FAILED++))
    fi
}

echo -e "${BLUE}📋 STEP 1: UI Polishing & Consistency${NC}"
check_file "lib/core/theme/app_theme.dart" "Theme file exists"
check_dependency "google_fonts" "Google Fonts dependency"
if grep -q "AppTheme.lightTheme()" lib/main.dart; then
    echo -e "${GREEN}✓${NC} Theme applied in main.dart"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Theme not applied in main.dart"
    ((FAILED++))
fi
echo ""

echo -e "${BLUE}📋 STEP 2: Loading States & Error Handling${NC}"
check_file "lib/core/utils/error_handler.dart" "Error handler utility"
if grep -q "ErrorHandler" lib/core/utils/error_handler.dart; then
    echo -e "${GREEN}✓${NC} ErrorHandler class found"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} ErrorHandler class not found"
    ((FAILED++))
fi
if grep -q "LoadingOverlay" lib/core/utils/error_handler.dart; then
    echo -e "${GREEN}✓${NC} LoadingOverlay widget found"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} LoadingOverlay widget not found"
    ((FAILED++))
fi
echo ""

echo -e "${BLUE}📋 STEP 3: Notifications & Reminders${NC}"
check_file "lib/core/services/notification_service.dart" "Notification service"
check_dependency "flutter_local_notifications" "Local notifications dependency"
check_dependency "timezone" "Timezone dependency"
check_dependency "shared_preferences" "Shared preferences dependency"
if grep -q "NotificationService" lib/core/services/notification_service.dart; then
    echo -e "${GREEN}✓${NC} NotificationService class found"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} NotificationService class not found"
    ((FAILED++))
fi
if grep -q "scheduleDailyExpenseReminder" lib/core/services/notification_service.dart; then
    echo -e "${GREEN}✓${NC} Daily reminder method found"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Daily reminder method not found"
    ((FAILED++))
fi
echo ""

echo -e "${BLUE}📋 STEP 4: Financial Literacy Section${NC}"
check_dir "lib/features/education" "Education directory"
check_file "lib/features/education/education_screen.dart" "Education screen"
if grep -q "Budgeting Basics" lib/features/education/education_screen.dart; then
    echo -e "${GREEN}✓${NC} Budgeting content found"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Budgeting content not found"
    ((FAILED++))
fi
if grep -q "Saving Strategies" lib/features/education/education_screen.dart; then
    echo -e "${GREEN}✓${NC} Saving strategies content found"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Saving strategies content not found"
    ((FAILED++))
fi
if grep -q "/education" lib/main.dart; then
    echo -e "${GREEN}✓${NC} Education route registered"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Education route not registered"
    ((FAILED++))
fi
echo ""

echo -e "${BLUE}📋 STEP 5: Settings Screen${NC}"
check_dir "lib/features/settings" "Settings directory"
check_file "lib/features/settings/settings_screen.dart" "Settings screen"
if grep -q "Enable Notifications" lib/features/settings/settings_screen.dart; then
    echo -e "${GREEN}✓${NC} Notification settings found"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Notification settings not found"
    ((FAILED++))
fi
if grep -q "Logout" lib/features/settings/settings_screen.dart; then
    echo -e "${GREEN}✓${NC} Logout functionality found"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Logout functionality not found"
    ((FAILED++))
fi
if grep -q "/settings" lib/main.dart; then
    echo -e "${GREEN}✓${NC} Settings route registered"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Settings route not registered"
    ((FAILED++))
fi
echo ""

echo -e "${BLUE}📋 Integration & Navigation${NC}"
if grep -q "Icons.school" lib/features/dashboard/dashboard_screen.dart; then
    echo -e "${GREEN}✓${NC} Education icon in dashboard"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Education icon not in dashboard"
    ((FAILED++))
fi
if grep -q "Icons.settings" lib/features/dashboard/dashboard_screen.dart; then
    echo -e "${GREEN}✓${NC} Settings icon in dashboard"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Settings icon not in dashboard"
    ((FAILED++))
fi
if grep -q "FloatingActionButton" lib/features/dashboard/dashboard_screen.dart; then
    echo -e "${GREEN}✓${NC} FAB button in dashboard"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} FAB button not in dashboard"
    ((FAILED++))
fi
echo ""

echo -e "${BLUE}📋 Documentation${NC}"
check_file "STEPS_1_5_IMPLEMENTATION.md" "Implementation documentation"
check_file "QUICK_START_GUIDE.md" "Quick start guide"
echo ""

# Summary
echo "================================================"
echo -e "${GREEN}✅ VERIFICATION SUMMARY${NC}"
echo "================================================"
echo ""
TOTAL=$((PASSED + FAILED))
PERCENTAGE=$((PASSED * 100 / TOTAL))

echo "Tests Passed: $PASSED"
echo "Tests Failed: $FAILED"
echo "Total Tests:  $TOTAL"
echo "Success Rate: $PERCENTAGE%"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! Implementation is complete.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run: flutter pub get"
    echo "  2. Run: flutter run"
    echo "  3. Test all features"
    echo "  4. Check notifications"
    echo "  5. Explore education section"
    echo "  6. Configure settings"
else
    echo -e "${YELLOW}⚠️  Some checks failed. Review the output above.${NC}"
    echo ""
    echo "To fix:"
    echo "  1. Check missing files"
    echo "  2. Verify dependencies in pubspec.yaml"
    echo "  3. Run: flutter pub get"
    echo "  4. Re-run this script"
fi

echo ""
echo "================================================"
echo -e "${BLUE}📚 Documentation Available:${NC}"
echo "================================================"
echo ""
echo "  • STEPS_1_5_IMPLEMENTATION.md - Complete technical docs"
echo "  • QUICK_START_GUIDE.md - User-friendly guide"
echo "  • This script - verify_steps_1_5.sh"
echo ""
echo "================================================"
