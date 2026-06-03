class AppConstants {
  static const String SUCCESS_TRUE = '1';
  static const String STATUS_TRUE = 'true';

  // Api Response Constants
  static const String SUCCESS = 'success';
  static const String STATUS = 'status';
  static const String MESSAGE = 'message';
  static const String RESULT = 'result';
  static const String DATA = 'data';

  // Shared Preferences Keys
  static const String PREF_MOBILE_NUMBER = "mobile_number";
  static const String PREF_IS_LOGGED_IN = "is_logged_in";
  static const String PREF_USER_DATA = "user_data";
  static const String PREF_KEEP_SIGNED_IN = "keep_signed_in";

  /* Api URLS*/
  static const String BASE_URL = "https://nlfs.in/erp/index.php";
  static const String LOGIN_API = "$BASE_URL/Api/login";
  static const String USER_REGISTRATION_API = "$BASE_URL/Api/list_registration";
  static const String ADD_REGISTRATION_API = "$BASE_URL/Api/add_registration";
  static const String FETCH_REGISTRATION_API = "$BASE_URL/Api/get_register_id";
  static const String UPDATE_REGISTRATION_API =
      "$BASE_URL/Api/update_registration";
  static const String DELETE_REGISTRATION_API =
      "$BASE_URL/Api/delete_registration";
  static const String ROLE_LIST_API = "$BASE_URL/Api/list_role";
  static const String DELETE_ROLE_API = "$BASE_URL/Api/delete_role";
  static const String BRANCH_LIST_API = "$BASE_URL/Erp/branch_list";
  static const String ADD_BRANCH_API = "$BASE_URL/Erp/add_branch";
  static const String DELETE_BRANCH_API = "$BASE_URL/Api/delete_branch";
  static const String ADD_ROLE_API = "$BASE_URL/Api/add_role";
  static const String ROLE_MANAGEMENT_API =
      "$BASE_URL/Nlf_Erp/list_role_management";
  static const String DEPARTMENT_LIST_API = "$BASE_URL/Erp/department_list";
  static const String ADD_DEPARTMENT_API = "$BASE_URL/Erp/add_department";
  static const String DELETE_DEPARTMENT_API = "$BASE_URL/Erp/delete_department";
  static const String UNIT_LIST_API = "$BASE_URL/Erp/unit_list";
  static const String ADD_UNIT_API = "$BASE_URL/Erp/add_unit";
  static const String DELETE_UNIT_API = "$BASE_URL/Erp/unit_list";
  static const String STAGE_LIST_API = "$BASE_URL/Erp/stage_list";
  static const String ADD_STAGE_API = "$BASE_URL/Erp/add_stage";
  static const String DELETE_STAGE_API = "$BASE_URL/Api/delete_stage";
  static const String SIGNATURE_LIST_API = "$BASE_URL/Api/list_signiture";
  static const String ADD_SIGNATURE_API = "$BASE_URL/Api/add_signiture";
  static const String DELETE_SIGNATURE_API = "$BASE_URL/Api/delete_signiture";
  static const String VENDOR_LIST_API = "$BASE_URL/Api/list_mst_vender";
  static const String ADD_VENDOR_API = "$BASE_URL/Api/add_mst_vender";
  static const String DELETE_VENDOR_API = "$BASE_URL/Api/delete_mst_vender";
  static const String BILLING_ADDRESS_LIST_API =
      "$BASE_URL/Erp/billing_address_list";
  static const String ADD_BILLING_ADDRESS_API =
      "$BASE_URL/Erp/add_billing_address";
  static const String FETCH_BILLING_ADDRESS_API =
      "$BASE_URL/Erp/get_billing_address_by_id";
  static const String UPDATE_BILLING_ADDRESS_API =
      "$BASE_URL/Erp/edit_billing_address";
  static const String DELETE_BILLING_ADDRESS_API =
      "$BASE_URL/Erp/delete_billing_address";
  static const String NEW_LEAD_LIST_API = "$BASE_URL/Api/list_new_lead";
  static const String ADD_LEAD_API = "$BASE_URL/Erp/add_lead";
  static const String FETCH_LEAD_API = "$BASE_URL/Api/get_new_lead_by_id";
  static const String DELETE_LEAD_API = "$BASE_URL/Erp/delete_lead_data";
  static const String UPDATE_LEAD_API = "$BASE_URL/Erp/update_lead_data";
  static const String UPDATE_LEAD_STAGE_API = "$BASE_URL/Erp/update_lead_stage";
  static const String EMPLOYEE_LIST_API = "$BASE_URL/Erp/employee_list";
  static const String EMPLOYEE_FETCH_BY_ID_API =
      "$BASE_URL/Nlf_Erp/get_emp_by_id";
  static const String QUOTATION_LIST_API = "$BASE_URL/Nlf_Erp/list_quotation";
  static const String UPDATE_ADMIN_APPROVAL_QUOTATION_API =
      "$BASE_URL/Nlf_Erp/update_admin_approval";
  static const String FETCH_CLIENT_DATA_API = "$BASE_URL/Erp/fetch_client_data";
  static const String SALES_FOLLOWUP_LIST_API =
      "$BASE_URL/Erp/sales_notification_new";
  static const String UPDATE_FOLLOWUP_API =
      "$BASE_URL/Erp/update_lead_emp_approval";
  static const String SALES_LOG_LIST_API = "$BASE_URL/Api/list_sales_log";
  static const String ADD_SALES_LOG_API = "$BASE_URL/Api/add_sales_log";
  static const String UPDATE_RATE_APPROVAL_API =
      "$BASE_URL/Nlf_Erp/update_rate_approval";
  static const String SEGMENT_LIST_API = "$BASE_URL/Nlf_Erp/list_mst_segment";
  static const String ADD_SEGMENT_API = "$BASE_URL/Nlf_Erp/add_mst_segment";
  static const String DELETE_SEGMENT_API =
      "$BASE_URL/Nlf_Erp/delete_mst_segment";
  static const String PRODUCT_TYPE_LIST_API = "$BASE_URL/Api/list_product_type";
  static const String ADD_PRODUCT_TYPE_API = "$BASE_URL/Api/add_product_type";
  static const String DELETE_PRODUCT_TYPE_API =
      "$BASE_URL/Api/delete_product_type";
  static const String PO_LIST_API = "$BASE_URL/Api/list_po";
  static const String UPDATE_ADMIN_APPROVAL_PO_API =
      "$BASE_URL/Nlf_Erp/update_po_approval";
  static const String ANNEXURE_PO_LIST_API =
      "$BASE_URL/Nlf_Erp/list_annexure_and_po";
  static const String UPDATE_ANNEXURE_APPROVAL_API =
      "$BASE_URL/Nlf_Erp/update_annexure_approval";
  static const String PRODUCT_LIST_API = "$BASE_URL/Api/list_mst_product";
  static const String ADD_PRODUCT_API = "$BASE_URL/Api/add_mst_product";
  static const String DELETE_PRODUCT_API = "$BASE_URL/Api/delete_mst_product";
  static const String FETCH_PRODUCT_API = "$BASE_URL/Api/get_mst_product_id";
  static const String ADD_PRODUCT_MST_API = "$BASE_URL/Erp/add_product_mst";
  static const String SUB_PRODUCT_LIST_API =
      "$BASE_URL/Api/list_mst_sub_product";
  static const String DELETE_SUB_PRODUCT_API =
      "$BASE_URL/Api/delete_mst_sub_product";
  static const String WORKORDER_LIST_API = "$BASE_URL/Api/list_work_order";
  static const String UPDATE_ACCOUNT_APPROVAL_WO_API =
      "$BASE_URL/Nlf_Erp/update_account_approval";
  static const String FETCH_WORK_ORDER_API =
      "$BASE_URL/Api/get_work_order_by_id";
  static const String PURCHASE_ORDER_LIST_API = "$BASE_URL/Api/list_po";
  static const String FETCH_PURCHASE_ORDER_API = "$BASE_URL/Api/get_po_id";
  static const String UPDATE_PURCHASE_ORDER_APPROVAL_API =
      "$BASE_URL/Nlf_Erp/update_po_approval";

  //static const String ANNEXTURE_PURCHASE_ORDER_LIST_API = "$BASE_URL/Nlf_Erp/list_annexure_and_po";
  static const String ANNEXTURE_PURCHASE_ORDER_LIST_API =
      "$BASE_URL/Nlf_Erp/getAnnexure_po";
  static const String GET_NEXT_DM_NO_API = "$BASE_URL/Nlf_Erp/get_next_dm_no";
  static const String ADD_DIRECT_DM_API = "$BASE_URL/Nlf_Erp/add_dm1";
  static const String DM_LIST_API = "$BASE_URL/Nlf_Erp/list_dm";
  static const String ADD_PO_API = "$BASE_URL/Api/add_po";
  //static const String ADD_DIRECT_DM_API = "$BASE_URL/Nlf_Erp/add_dm1";

  static const String ADD_EMPLOYEE_API = "$BASE_URL/Erp/add_employee";
  static const String FETCH_EMPLOYEE_DATA_API = "$BASE_URL/Erp/get_employee_by_id";
  static const String DELETE_EMPLOYEE_DATA_API = "$BASE_URL/Erp/delete_employee_data";
  static const String UPDATE_EMPLOYEE_DATA_API = "$BASE_URL/Erp/update_employee";



  static const String JOB_APPLICATION_LIST_API = "$BASE_URL/Nlf_Erp/getJobApplication";
  static const String ADD_JOB_APPLICATION_API = "$BASE_URL/Nlf_Erp/add_application";
  static const String FETCH_JOB_APPLICATION_API = "$BASE_URL/Nlf_Erp/getJobApplicationById";
  static const String DELETE_JOB_APPLICATION_API = "$BASE_URL/Nlf_Erp/deleteJobApplication";
  static const String UPDATE_JOB_APPLICATION_API = "$BASE_URL/Nlf_Erp/updateJobApplicationStatus";
  static const String ADD_LEAVE_API = "$BASE_URL/Api/add_live";
  static const String OFFER_LETTER_LIST_API = "$BASE_URL/Nlf_Erp/getOfferLatter";
  static const String ADD_OFFER_LETTER_API = "$BASE_URL/Nlf_Erp/addOfferLatter";
  static const String DELETE_OFFER_LETTER_API = "$BASE_URL/Nlf_Erp/deleteOfferLatter";
  static const String UPDATE_OFFER_LETTER_STATUS_API = "$BASE_URL/Nlf_Erp/updateOfferLetter";
  static const String APPOINTMENT_LETTER_LIST_API = "$BASE_URL/Nlf_Erp/getAppointment";
  static const String ADD_APPOINTMENT_LETTER_API = "$BASE_URL/Nlf_Erp/addAppointment";
  static const String DELETE_APPOINTMENT_LETTER_API = "$BASE_URL/Nlf_Erp/deleteAppointment";
  static const String FETCH_APPOINTMENT_DATA_API = "$BASE_URL/Nlf_Erp/getAppointmentById";
  static const String UPDATE_APPOINTMENT_LETTER_API = "$BASE_URL/Nlf_Erp/updateAppointment";
  static const String ATTENDANCE_LIST_API = "$BASE_URL/Api/list_attendance";
  static const String ATTENDANCE_GET_LIST_API = "$BASE_URL/Nlf_Erp/getAttendance";
  static const String UPDATE_LEAVE_APPROVAL_API = "$BASE_URL/Api/update_leave";
  static const String UPCOMING_BIRTHDAYS_API = "$BASE_URL/Api/upcoming_birthdays";
  static const String FETCH_ATTENDANCE_API = "$BASE_URL/Nlf_Erp/getAttendanceByID";

}
