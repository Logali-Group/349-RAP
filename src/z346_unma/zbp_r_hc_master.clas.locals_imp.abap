class lcl_buffer definition.

  public section.

    constants: created type c length 1 value 'C',
               updated type c length 1 value 'U',
               deleted type c length 1 value 'D'.

    types: begin of ty_buffer_master.
             include type zhc_master as data.
    types:   flag type c length 1,
           end of ty_buffer_master.

    types: tt_master type sorted table of ty_buffer_master with unique key e_name.

    class-data mt_buffer_master type tt_master.

endclass.

class lhc_HCMMaster definition inheriting from cl_abap_behavior_handler.
  private section.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for HCMMaster result result.

    methods create for modify
      importing entities for create HCMMaster.

    methods update for modify
      importing entities for update HCMMaster.

    methods delete for modify
      importing keys for delete HCMMaster.

    methods read for read
      importing keys for read HCMMaster result result.

    methods lock for lock
      importing keys for lock HCMMaster.

endclass.

class lhc_HCMMaster implementation.

  method get_instance_authorizations.
  endmethod.

  method create.

    data ls_buffer type lcl_buffer=>ty_buffer_master.

    get time stamp field data(lv_tsl).

    select max( e_number ) as e_number
           from zhc_master
           into @data(lv_e_number).

    loop at entities into data(ls_entities).

      ls_buffer-data-e_number = lv_e_number + 1.
      ls_buffer-data-crea_date_time = lv_tsl.
      ls_buffer-data-crea_uname = sy-uname.
      ls_buffer-data-e_name = ls_entities-%data-EmployeeName.
      ls_buffer-data-e_department = ls_entities-%data-EmployeeDepartment.
      ls_buffer-data-status = ls_entities-%data-EmployeeStatus.
      ls_buffer-data-job_title = ls_entities-%data-JobTitle.
      ls_buffer-data-start_date = ls_entities-%data-StartDate.
      ls_buffer-data-end_date = ls_entities-%data-EndDate.
      ls_buffer-data-email = ls_entities-%data-Email.
      ls_buffer-data-m_number = ls_entities-%data-ManagerNumber.
      ls_buffer-data-m_name = ls_entities-%data-ManagerName.
      ls_buffer-data-m_department = ls_entities-%data-ManagerDepartment.
      ls_buffer-data-crea_date_time = ls_entities-%data-CreatedOn.
      ls_buffer-data-crea_uname = ls_entities-%data-CreatedBy.

      ls_buffer-flag = lcl_buffer=>created.

      insert ls_buffer into table lcl_buffer=>mt_buffer_master.

      if ls_entities-%cid is not initial.
        insert value #( %cid           = ls_entities-%cid
                        EmployeeNumber = ls_entities-EmployeeNumber ) into table mapped-hcmmaster.
      endif.

    endloop.

  endmethod.

  method update.

    loop at entities into data(ls_entities).

      get time stamp field ls_entities-%data-ChangedOn.
      ls_entities-%data-ChangedBy = sy-uname.

      select single * from zhc_master
             where e_number eq @ls_entities-EmployeeNumber
             into @data(ls_ddbb).

      if sy-subrc eq 0.


        insert value #( flag = lcl_buffer=>updated
                        data = value #( e_name = cond #( when ls_entities-%control-EmployeeName = if_abap_behv=>mk-on
                                                         then ls_entities-EmployeeName
                                                         else ls_ddbb-e_name )

                                        e_department = cond #( when ls_entities-%control-EmployeeDepartment = if_abap_behv=>mk-on
                                                               then ls_entities-EmployeeDepartment
                                                               else ls_ddbb-e_department )

                                        status       = cond #( when ls_entities-%control-EmployeeStatus = if_abap_behv=>mk-on
                                                                 then ls_entities-EmployeeStatus
                                                                 else ls_ddbb-status )

                                          job_title    = cond #( when ls_entities-%control-JobTitle = if_abap_behv=>mk-on
                                                                 then ls_entities-JobTitle
                                                                 else ls_ddbb-job_title )

                                          start_date   = cond #( when ls_entities-%control-StartDate = if_abap_behv=>mk-on
                                                                 then ls_entities-StartDate
                                                                 else ls_ddbb-start_date )

                                          end_date     = cond #( when ls_entities-%control-EndDate = if_abap_behv=>mk-on
                                                                 then ls_entities-EndDate
                                                                 else ls_ddbb-end_date )

                                          email        = cond #( when ls_entities-%control-Email = if_abap_behv=>mk-on
                                                                 then ls_entities-Email
                                                                 else ls_ddbb-email )
                                          m_number     = cond #( when ls_entities-%control-ManagerNumber = if_abap_behv=>mk-on
                                                                 then ls_entities-ManagerNumber
                                                                 else ls_ddbb-m_number )

                                          m_name       = cond #( when ls_entities-%control-ManagerName = if_abap_behv=>mk-on
                                                                 then ls_entities-ManagerName
                                                                 else ls_ddbb-m_name )

                                          m_department = cond #( when ls_entities-%control-ManagerDepartment = if_abap_behv=>mk-on
                                                                 then ls_entities-ManagerName
                                                                 else ls_ddbb-m_department )

                                          e_number       = ls_entities-EmployeeNumber
                                          crea_date_time = ls_ddbb-crea_date_time
                                          crea_uname     = ls_ddbb-crea_uname
                            ) ) into table lcl_buffer=>mt_buffer_master.

        if ls_entities-EmployeeNumber is not initial.
          insert value #( %cid           = ls_entities-EmployeeNumber
                          EmployeeNumber = ls_entities-EmployeeNumber ) into table mapped-hcmmaster.
        endif.
      endif.
    endloop.

  endmethod.

  method delete.

    loop at keys into data(ls_entities).
      insert value #( flag = lcl_buffer=>deleted
                      data = value #( e_number = ls_entities-EmployeeNumber ) ) into table lcl_buffer=>mt_buffer_master.
      if ls_entities-EmployeeNumber is not initial.
        insert value #( %cid           = ls_entities-EmployeeNumber
                        EmployeeNumber = ls_entities-EmployeeNumber ) into table mapped-hcmmaster.
      endif.
    endloop.

  endmethod.

  method read.
  endmethod.

  method lock.
  endmethod.

endclass.

class lsc_Z_R_HC_MASTER definition inheriting from cl_abap_behavior_saver.
  protected section.

    methods finalize redefinition.

    methods check_before_save redefinition.

    methods save redefinition.

    methods cleanup redefinition.

    methods cleanup_finalize redefinition.

endclass.

class lsc_Z_R_HC_MASTER implementation.

  method finalize.
  endmethod.

  method check_before_save.
  endmethod.

  method save.

    data: lt_data_created type standard table of zhc_master,
          lt_data_updated type standard table of zhc_master,
          lt_data_deleted type standard table of zhc_master.

    lt_data_created = value #( for <row> in lcl_buffer=>mt_buffer_master where ( flag = lcl_buffer=>created ) ( <row>-data ) ).

    if lt_data_created is not initial.
     insert zhc_master from table @lt_data_created.
    endif.

    lt_data_updated = value #( for <row> in lcl_buffer=>mt_buffer_master where ( flag = lcl_buffer=>updated ) ( <row>-data ) ).

    if lt_data_updated is not initial.
      update zhc_master from table @lt_data_updated.
    endif.

    lt_data_deleted = value #( for <row> in lcl_buffer=>mt_buffer_master where ( flag = lcl_buffer=>deleted ) ( <row>-data ) ).

    if lt_data_deleted is not initial.
      delete zhc_master from table @lt_data_deleted.
    endif.

  endmethod.

  method cleanup.
  endmethod.

  method cleanup_finalize.
  endmethod.

endclass.
