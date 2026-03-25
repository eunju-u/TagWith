class AppStrings {
  // --- 공통 ---
  static const String appName = 'TagWith';
  static const String tagline = '태그로 연결되는 스마트 가계부';
  static const String ok = '확인';
  static const String cancel = '취소';
  static const String save = '저장';
  static const String delete = '삭제';
  static const String edit = '수정';
  static const String error = '오류';
  static const String warning = '주의';
  static const String success = '성공';
  static const String add = '추가';
  static const String close = '닫기';
  static const String none = '없음';

  // --- 날짜 포맷 ---
  static const String dateFormatMonthly = 'yyyy년 MM월';
  static const String dateFormatYearly = 'yyyy년';

  // --- 홈 ---
  static const String entryMenuTitle = '가계부 기록 방식 선택';
  static const String ocrMenuLabel = '영수증 분석';
  static const String manualEntryLabel = '직접 입력';
  static const String pdfExportLabel = 'PDF 만들기';

  // --- 인증, 로그인 --
  static const String loginTitle = '환영합니다';
  static const String emailHint = '이메일';
  static const String passwordHint = '비밀번호';
  static const String nameHint = '이름';
  static const String loginButton = '로그인';
  static const String signUpButton = '회원가입';
  static const String forgotPasswordQuestion = '비밀번호를 잊으셨나요?';
  static const String alreadyHaveAccount = '이미 계정이 있으신가요? 로그인';
  static const String loginSuccess = '로그인에 성공했습니다!';
  static const String loginFailed = '로그인에 실패했습니다.';
  static const String enterEmail = '이메일을 입력해 주세요.';
  static const String dailyLimitExceeded = '오늘 인증 요청 한도(5회)를 초과했습니다.';
  static const String verificationCodeSent = '인증 코드가 발송되었습니다.';
  static const String verificationCodeFailed = '코드 발송에 실패했습니다.';
  static const String verificationCodeHint = '인증 코드';
  static const String verificationRequest = '인증 요청';
  static const String verificationDone = '인증 완료됨';
  static const String completeEmailVerification = '이메일 인증을 완료해 주세요.';
  static const String signUpSuccess = '회원가입 성공!';
  static const String signUpFailed = '회원가입 실패';
  static const String forgotPasswordTitle = '비밀번호 찾기';
  static const String enterRegisteredEmail = '가입된 이메일';
  static const String getVerificationCode = '인증 코드 받기';
  static const String resendVerificationCode = '인증 코드 재발송';
  static const String verificationSuccess = '인증에 성공했습니다!';
  static const String invalidVerificationCode = '인증 번호가 올바르지 않습니다.';
  static const String newPasswordHint = '새 비밀번호';
  static const String resetPasswordButton = '비밀번호 재설정';
  static const String passwordChangedSuccess = '비밀번호가 변경되었습니다.';
  static const String passwordChangeFailed = '변경 실패';
  static const String backToLogin = '로그인으로 돌아가기';

  // --- OCR, 영수증 ---
  static const String ocrAnalyzing = '영수증을 분석 중입니다...';
  static const String ocrLimitTitle = '일일 분석 한도 초과';
  static const String ocrLimitMessage = '일일 영수증 분석 한도를 모두 사용하셨습니다.';
  static const String ocrPickImage = '분석할 영수증 사진을 선택해 주세요.';
  static const String ocrSuccess = '영수증 분석을 완료했습니다.';
  static const String ocrFailed = '영수증 분석에 실패했습니다. 다시 시도해 주세요.';
  static const String ocrReviewTitle = '분석 결과 확인';
  static const String ocrSavingStatus = '정보를 저장하고 있어요...';
  static const String ocrWaitMessage = '잠시만 기다려 주세요';
  static const String ocrProcessedAll = '모든 내역이 처리되었습니다.';
  static const String ocrBackToHomeLabel = '홈으로 돌아가기';
  static const String ocrAnalyzedHistoryTitle = '분석된 내역';
  static const String ocrReviewGuide = '내용을 확인하고 저장해 주세요.';
  static const String ocrDuplicateFoundTitle = '중복 내역 발견';
  static const String ocrDuplicateFoundMessage = '이미 저장된 것으로 보이는 내역이 있습니다. 그래도 저장하시겠습니까?';
  static const String ocrDuplicateItemLabel = '이미 저장된 내역입니다';
  static const String ocrPaymentMethodPickerTitle = '결제 수단 선택';
  static const String ocrRelationTagActionLabel = '관계(태그)';
  static const String ocrSaveSuccessMessageSuffix = '건의 내역이 저장되었습니다.';
  static const String ocrSaveErrorMessage = '저장 중 오류가 발생했습니다: ';

  // --- 가계부 입력 ---
  static const String manualEntryTitle = '직접 입력';
  static const String expenseLabel = '지출';
  static const String incomeLabel = '수입';
  static const String amountLabel = '금액';
  static const String amountExpensePrompt = '얼마를 쓰셨나요?';
  static const String amountIncomePrompt = '얼마를 버셨나요?';
  static const String amountHint = '0';
  static const String currencyUnit = '원';
  static const String descriptionLabel = '내용';
  static const String descriptionHint = '무엇에 쓰셨나요?';
  static const String paymentMethodLabel = '결제 수단';
  static const String cashLabel = '현금';
  static const String checkCardLabel = '체크카드';
  static const String creditCardLabel = '신용카드';
  static const String cardLabel = '카드';
  static const String dateLabel = '날짜';
  static const String categoryLabel = '카테고리';
  static const String relationLabel = '관계 (태그)';
  static const String selectCategoryHint = '선택해주세요';
  static const String saveComplete = '기록이 완료되었습니다!';
  static const String updateComplete = '수정되었습니다!';
  static const String saveFailed = '저장에 실패했습니다. 다시 시도해 주세요.';
  static const String entryIncompleteError = '금액과 내용을 입력해 주세요.';
  static const String completeEntryButton = '기록 완료하기';
  static const String completeEditButton = '수정 완료하기';

  // --- 카테고리 명칭 ---
  static const String categoryFood = '식비';
  static const String categoryCafe = '카페/간식';
  static const String categoryTransport = '교통';
  static const String categoryShopping = '생활/쇼핑';
  static const String categoryMisc = '기타';

  // --- 달력 및 내역 관리 ---
  static const String yearLabel = '연';
  static const String monthLabel = '월';
  static const String weekLabel = '주';
  static const String totalIncomeLabel = '총 수입';
  static const String totalExpenseLabel = '총 지출';
  static const String noDataMessage = '내역이 없습니다';
  static const String deleteTransactionTitle = '내역 삭제';
  static const String deleteTransactionConfirm = '정말로 이 내역을 삭제하시겠습니까?';
  static const String deleteSubmitButton = '삭제하기';
  static const String deleteSuccess = '삭제되었습니다.';
  static const String deleteFailed = '삭제에 실패했습니다.';
  static const String helpTitle = '도움말';
  static const String helpContent = '• 내역을 왼쪽으로 스와이프하면 삭제할 수 있습니다.\n• 내역을 클릭하면 내용을 수정할 수 있습니다.';
  static const String transactionDetailPopupSuffix = '내역';
  static const String filterTitle = '필터 설정';
  static const String filterReset = '초기화';
  static const String filterSectionType = '구분';
  static const String filterAll = '전체';
  static const String filterSectionCategory = '1차 태그 (카테고리)';
  static const String filterSectionRelation = '2차 태그 (관계)';
  static const String filterApply = '적용하기';
  static const String addTagTitle = '새 태그 추가';
  static const String addTagHint = '태그 이름을 입력하세요 (예: 친구, 가족)';
  static const String relationPickerTitle = '관계 (태그) 선택';

  // --- 통계 및 분석 ---
  static const String monthlyLabel = '월간';
  static const String yearlyLabel = '연간';
  static const String totalMonthlyExpense = '이번 달 총 지출';
  static const String totalYearlyExpense = '올해 총 지출';
  static const String monthlyStatusSuffix = '현황';
  static const String incDecPrefix = '지난달보다';
  static const String increaseSuffix = '늘었어요';
  static const String decreaseSuffix = '줄었어요';
  static const String futureExpenseMessage = '미래 지출은 아직 0원이에요 📅';
  static const String trendTitleMonthly = '최근 수입/지출 추이';
  static const String trendTitleYearly = '월별 수입/지출 추이';
  static const String categorySpendingTitle = '카테고리별 지출';
  static const String noExpenseDataMessage = '기록된 지출 내역이 없습니다';
  static const String totalExpenseSummary = '지출합계';
  static const String paymentMethodSpendingTitle = '결제 수단별 지출';
  static const String tagSpendingTitle = '태그별 지출';
  static const String noTagDataMessage = '기록된 태그가 없습니다';
  static const String insightTitle = '이번 달 소비 인사이트';
  static const String smartAnalysisLabel = '스마트 분석';
  static const String avgDailyExpenseLabel = '하루 평균 지출';
  static const String mostSpentWeekdayLabel = '최다 지출 요일';
  static const String expenseVelocityCheck = '지출 속도 체크';
  static const String spendingCheckDay = '소비 점검일';
  static const String noDataInsight = '데이터 없음';

  // --- 예산 및 AI 추천 ---
  static const String budgetManagementTitle = '이번 달 예산 관리';
  static const String editGoalButton = '목표 수정';
  static const String currentSpendingLabel = '현재까지 지출';
  static const String budgetGoalLabelPrefix = '목표';
  static const String remainingBudgetLabel = '남은 예산';
  static const String overBudgetLabel = '예산 초과';
  static const String canSpendLabel = '지출 가능';
  static const String dailyRecommendLabel = '하루 권장';
  static const String dailySpendLimitLabel = '이하 지출 권장';
  static const String budgetDialogTitle = '한 달 예산 설정';
  static const String budgetHint = '예산을 입력하세요';
  static const String budgetHelpTitle = '하루 권장 지출액이란?';
  static const String budgetHelpContent = '예산이 30만 원 남았고, 이번 달이 10일 남았다면?\n300,000 ÷ 10 = 30,000원이 하루 권장 지출액으로 표시됩니다.\n\n내일 돈을 많이 쓰면 남은 예산이 줄어들어, 다음 날의 권장 지출액은 자동으로 낮아지게 됩니다!';
  static const String lunchRecommendModeTitle = '점심 추천 모드';
  static const String lunchRecommendActiveSub = '위치 기반 추천 모드 활성화됨';
  static const String lunchRecommendInactiveSub = '권장금액 기반 식당 추천';
  static const String nearbyStoreSearchButton = '주변 가게 찾기';
  static const String nearbyRecommendationTitle = '주변 추천 장소';
  static const String countSuffix = '곳';
  static const String naverMapTitleSuffix = '주변 네이버 지도';
  static const String locationServiceDisabled = '위치 서비스가 꺼져 있습니다.';
  static const String locationFetchError = '정보를 가져오지 못했습니다.';
  static const String budgetTipFull = '이번 달 예산을 모두 소진하셨네요! 이제부터는 필수적인 지출만 고려해서 남은 기간을 잘 마무리해 봅시다. 💪';
  static const String budgetTipOver = '예산을 초과했습니다! 이번 달 남은 기간은 최대한 지출을 자제하는 긴축 재정 필요해요. 🚨';
  static const String budgetTipCritical = '하루 5천 원도 안 남았어요! 비상 상황입니다. 당분간은 지갑을 닫고 생존 모드로 들어가야 할 것 같아요! 😱';
  static const String budgetTipWarning = '하루 권장액이 1.5만 원 미만입니다. 당분간은 비싼 커피나 외식 대신 도시락이나 집밥을 애용해 보는 건 어떨까요? 🍱';
  static const String budgetTipCaution = '예산의 80%를 이미 사용하셨네요. 남은 날짜가 많다면 조금 더 계획적인 소비가 필요해 보여요! 📉';
  static const String budgetTipGood = '지출 속도가 아주 훌륭합니다! 지금처럼만 계획적으로 소비하신다면 이번 달 예산을 멋지게 지켜낼 수 있어요. ✨';
  static const String saveModeTag = '절약 모드';
  static const String rationalSpendingTag = '합리적 소비';
  static const String todayFlexTag = '오늘의 flex';
  static const String nearbyConvenienceTitle = '가까운 편의점 추천';
  static const String nearbyConvenienceDesc = '남은 예산이 빠듯해요!\n가까운 편의점에서 알뜰한 점심 한 끼 어떠세요?';
  static const String nearbyRationalTitle = '가성비 식당';
  static const String nearbyRationalDesc = '주변의 가성비 좋은 식당을 추천드려요.\n오늘 권장 금액 내에서 든든하게 드실 수 있습니다!';
  static const String nearbyFlexTitle = '오늘은 맛집으로!';
  static const String nearbyFlexDesc = '예산에 여유가 충분합니다.\n주변 평점 좋은 식당에서 기분 좋은 점심을 즐겨보세요!';
  static const String searchConvenience = '주변 편의점';
  static const String searchRestaurant = '주변 맛집';
  static const String keywordConvenience = '편의점';
  static const String keywordRestaurant = '맛집';
  static const String keywordCafe = '맛집 카페';
  static const String mapLocationDetected = '추천 장소 위치 탐색됨';
  static const String nearbyDistanceLabel = '주변';

  // --- PDF 만들기 ---
  static const String pdfCreatorTitle = '영수증 PDF 만들기';
  static const String pdfGuideTitle = '사용 가이드';
  static const String pdfGuideReorderTitle = '순서 변경 (Long Click)';
  static const String pdfGuideReorderDesc = '항목을 길게 눌러 원하는 위치로 이동하세요.';
  static const String pdfGuideSaveTitle = 'PDF 저장 방법';
  static const String pdfGuideSaveDesc = '상단 "저장" 버튼을 눌러 공유하거나 기기에 저장하세요.';
  static const String pdfSuccessMessage = 'PDF가 성공적으로 생성 및 전달되었습니다.';
  static const String pdfDefaultFileNamePrefix = 'receipt_report_';
  static const String pdfDefaultSubject = '영수증 PDF 보고서';
  static const String pdfTitleHint = '제목을 입력하세요';
  static const String pdfAddItemTitle = '추가할 항목 선택';
  static const String pdfTypeTextLabel = '텍스트 (내용 입력)';
  static const String pdfTypeImageLabel = '이미지 (영수증 사진)';
  static const String pdfContentHint = '내용을 입력하세요.';
  static const String pdfEmptyError = '내용을 입력해 주세요.';

  // --- 설정 ---
  static const String settingsTitle = '설정';
  static const String accountSection = '계정';
  static const String displaySection = '화면 설정';
  static const String infoSection = '정보';
  static const String defaultUser = '사용자';
  static const String logout = '로그아웃';
  static const String withdraw = '회원 탈퇴';
  static const String withdrawSubmit = '탈퇴하기';
  static const String confirmLogout = '정말 로그아웃 하시겠습니까?';
  static const String logoutSuccess = '로그아웃 되었습니다.';
  static const String confirmWithdraw = '정말 탈퇴하시겠습니까?\n탈퇴 시 모든 정보가 영구적으로 삭제되며 복구할 수 없습니다.';
  static const String withdrawSuccess = '탈퇴 처리가 완료되었습니다.';
  static const String withdrawError = '회원 탈퇴 처리 중 오류가 발생했습니다.';
  static const String systemTheme = '시스템 설정';
  static const String lightTheme = '라이트 모드';
  static const String darkTheme = '다크 모드';
  static const String versionInfo = '버전 정보';
}
