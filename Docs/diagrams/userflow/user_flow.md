# SkillBit Rebirth - Comprehensive User Flow Documentation

This document outlines the complete user journey across authentication, courses, quizzes, contests, friendly matches, and the store/profile systems, derived from the project's master architectural diagram.

---

## 1. Authentication & Onboarding Flow
Handles initial registration, secure login, social sign-in, email verification, and password recovery.

```mermaid
graph TD
    Start([Start]) --> LoginChoice{Login or Signup?}

%% Login & Social Login Branch
    LoginChoice -->|Login / Social Login| CheckFirstTime{First Time?}
    LoginChoice -->|Sign Up| Signup[Sign Up]
    LoginChoice -->|Social Sign-up| SocialSignup[Sign up via Social Login]
    SocialSignup --> CheckFirstTime
    Signup --> OTPVerify[OTP Verification for Email]
    OTPVerify --> OTPInput[Enter OTP Code]
    OTPInput --> CheckFirstTime

%% Forgot Password Sub-flow
    LoginChoice -->|Forgot Password| ForgotPwd[Forgot Password]
    ForgotPwd --> EnterEmail[Enter Email]
    EnterEmail --> SendOTP[Verify Email & Send OTP]
    SendOTP --> InputCode[Enter OTP Code]
    InputCode --> ChangePwd[Change Password]
    ChangePwd --> SuccessCheck{Success?}
    SuccessCheck -->|Yes| CheckFirstTime
    SuccessCheck -->|No| ChangePwd

%% First Time Split
    CheckFirstTime -->|Yes| Onboarding[Show Onboarding]
    CheckFirstTime -->|No| Home[Home Page]
    Onboarding --> Home

%% Main Navigation
    Home --> Levels[Levels Screen]
    Home --> SearchCourses[Search Courses]
    Home --> Store[Store / Shop]
    Home --> FriendlyMatch[Friendly Match]
    Home --> Contest[Contest Module]
    Home --> Profile[Profile & Settings]

%% Course Flow
    Levels --> CourseCard[Course Card Per Level]
    SearchCourses --> CourseCard
    CourseCard --> CourseOverview[Course Overview Page]
    CourseOverview --> EnrolledCheck{Enrolled?}
    EnrolledCheck -->|No| Enroll[Enroll Action]
    Enroll --> ViewContent[View Lessons & Quizzes]
    EnrolledCheck -->|Yes| ViewContent
    ViewContent --> LessonPage[Lesson Page]
    LessonPage --> RunCode[Run Code / Interact with Examples]
    LessonPage --> MarkComplete[Mark Complete -> End]
    LessonPage --> TakeQuiz[Take Quiz]
    TakeQuiz --> QuizResults[Quiz Results]
    QuizResults --> ScoreCheck{Score >= 75%?}
    ScoreCheck -->|No| RetryQuiz[Retry Quiz / Re-take]
    RetryQuiz --> TakeQuiz
    ScoreCheck -->|Yes| PostQuizChoice{Where to go?}
    PostQuizChoice -->|Review Answers| ReviewAnswers[Review Answers & Hints]
    PostQuizChoice -->|Next Lesson| ViewContent
    ReviewAnswers --> ShowHints[Show Hints for Answers]
    ShowHints --> QuizResults

%% Level Progress & Unlocks
    CourseOverview -->|After Finishing Course| GainedPoints[Gained Points]
    GainedPoints --> CheckLast{Last course in level?}
    CheckLast -->|Yes| UnlockLevel[Unlocked New Level]
    UnlockLevel --> LevelAchievement[Gained Achievement for Unlocking Level]
    LevelAchievement --> Level1Check{Finished Level 1?}
    Level1Check -->|Yes| ContestOverview[Contest Overview]
    Level1Check -->|No| End([End])

%% Contest Sub-flow
    ContestOverview --> EnrollContest[Enroll in Contest]
    EnrollContest --> EnterContest[Enter Contest Area]
    EnterContest --> TimerStarts[Timer Starts]
    EnterContest --> ContestResults[Contest Results]
    ContestResults --> EarlyFinish{If user finished early?}
    EarlyFinish -->|Yes| WaitEnd[Waiting for Contest to End]
    WaitEnd --> ResultsNav[Results Decision Hub]
    EarlyFinish -->|No| ResultsNav
    ResultsNav --> ReviewContestAnswers[Review Answers & Hints]
    ResultsNav --> Leaderboard[Leaderboard]
    ResultsNav --> BackHome[Go Back to Home -> END]

%% Friendly Match Flow
    FriendlyMatch --> MatchGrounds[Match Grounds Page]
    MatchGrounds --> JoinOrCreate{Join or Create?}
    JoinOrCreate -->|Create Match| CreateMatch[Create a Match]
    CreateMatch --> InviteFriend[Invite a Friend]
    InviteFriend --> Compete[Compete Live]
    Compete --> SeeResults[See Match Results]
    JoinOrCreate -->|Accept Invitation| AcceptInvite[Accept Invitation]
    AcceptInvite --> Compete
    JoinOrCreate -->|Decline Match| Decline[Decline & Return]
    Decline --> MatchGrounds

%% Store Flow
    Store --> SearchCosmetics[Search Cosmetics]
    Store --> FilterCosmetics[Filter Cosmetics]
    Store --> PurchaseCosmetic[Purchase Cosmetic Item]
    PurchaseCosmetic --> ProcessPurchase[Processing Purchase]
    ProcessPurchase --> EquipCosmetic[Equip Cosmetic]

%% Profile Flow
    Profile --> Achievements[Achievement Page]
    Profile --> Badges[Badge Page]
    Profile --> Settings[Settings & Preferences]
    Profile --> Friends[Friends Hub]
    Profile --> AboutApp[About the App]
    Friends --> SearchFriends[Search Friends]
    Friends --> ViewRequests[View Sent/Received Requests]
    Friends --> ViewFriendProfile[View Friend Profile]
    AboutApp --> DevNotes[Developer's Notes]
    AboutApp --> ContactUs[Contact Us]
```