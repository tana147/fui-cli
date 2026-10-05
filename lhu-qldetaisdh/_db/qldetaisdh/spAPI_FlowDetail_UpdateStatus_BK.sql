
--SELECT * FROM FLOW_DETAIL where flow

CREATE PROCEDURE [dbo].[spAPI_FlowDetail_UpdateStatus_BK] -- '922000123', 2, 24396, 13, 124, 'C', 'GV0000611', 9
    @Student_ID VARCHAR(20),
    @Process_ID INT,
    @Flow_ID INT,
    @Task_ID INT,
    @Task_Detail_ID INT,
    @Flow_Detail_Status VARCHAR(20),
    @sys_UserID VARCHAR(9),
    @sys_SystemRight INT
AS
    BEGIN
        DECLARE @MsgError NVARCHAR(500);
        IF(@sys_SystemRight NOT IN (1, 2, 3, 9))
            BEGIN
                SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này ';
                RAISERROR(@MsgError, 16, 1);
                RETURN 0;
            END;
        DECLARE @ERRCODE INT;
        DECLARE @err_location VARCHAR(1000);
        DECLARE @task_parent INT;
        SELECT
            @task_parent = Task_Begin
        FROM Process
        WHERE Process_ID = @Process_ID;
        SET @err_location = '[FlowDetail_UpdateStatus]-Student['+CAST(@Student_ID AS VARCHAR)+']-Process['+CAST(@Process_ID AS VARCHAR)+']-Task['++CAST(@Task_ID AS VARCHAR)+']-Task_Detail['+CAST(@Task_Detail_ID AS VARCHAR)+']';
        DECLARE
            @last_flow_status    VARCHAR(100),
            @last_task_id        INT,
            @last_flow_id        INT,
            @last_task_detail_id INT,
            @NOW_STATUS          VARCHAR(20);
        BEGIN TRY
            BEGIN TRANSACTION;
            IF(NOT EXISTS (
                          SELECT
                              1
                          FROM Process_Student
                          WHERE Process_ID     = @Process_ID
                                AND Student_ID = @Student_ID
                                AND use_yn     = 1
                          )
              )
                BEGIN
                    SET @err_location = @err_location+'[PROCESS_STUDENT] Data does not exists';
                    RAISERROR(@err_location, 16, 1);
                    RETURN 0;
                END;

            --print @Flow_Detail_Status
            UPDATE
                Flow_Detail
            SET
                Flow_Detail_Status = @Flow_Detail_Status,
                [Updated_By] = @sys_UserID,
                [Updated_At] = GETDATE()
            WHERE Flow_ID            = @Flow_ID
                  AND Task_ID        = @Task_ID
                  AND Task_Detail_ID = CASE WHEN @Task_Detail_ID IS NULL
                                                 OR @Task_Detail_ID = 0 THEN Task_Detail_ID
                                            ELSE @Task_Detail_ID END;

            --PRINT CASE WHEN @Task_Detail_ID IS NULL OR @Task_Detail_ID =0 THEN 'NULL' ELSE @Task_Detail_ID END

            --exec by task_id

            --exec dbo.FLow_UpdateStatus @Student_ID, @Process_ID, @TASK_ID, @user_id, @ERRCODE out, @err_location out

            --exec full tree
            EXEC dbo.FLow_UpdateStatusFull
                @Student_ID,
                @Process_ID,
                0,
                @sys_UserID,
                @ERRCODE OUT,
                @err_location OUT;

            --checking next step of NCKH

            --update flow_detail of NCKH if not yet modify
            UPDATE
                b
            SET
                b.Flow_Status = 'W'
            FROM Flow_Detail a
                 INNER JOIN(
                           SELECT
                               Student_ID,
                               Process_ID,
                               Flow_ID,
                               Task_ID,
                               Flow_Status
                           FROM Flow
                           WHERE Student_ID     = @Student_ID
                                 AND Process_ID = @Process_ID
                                 AND use_yn     = 1
                           ) b ON b.Flow_ID                       = a.Flow_ID
                                  AND b.Task_ID                   = a.Task_ID
                 INNER JOIN Task_Detail c ON a.Task_ID            = c.Task_ID
                                             AND a.Task_Detail_ID = c.Task_Detail_ID
                                             AND c.User_Input     = 'SDH'
            WHERE a.Flow_Detail_Status = 'P'

            --and File_Name is null and text_content is null Em Tâm rào lại
            ;

            --select A.*
            UPDATE
                a
            SET
                a.Flow_Detail_Status = 'W'
            FROM Flow_Detail a
                 INNER JOIN(
                           SELECT
                               Student_ID,
                               Process_ID,
                               Flow_ID,
                               Task_ID
                           FROM Flow
                           WHERE Student_ID     = @Student_ID
                                 AND Process_ID = @Process_ID
                                 AND use_yn     = 1
                           ) b ON b.Flow_ID                       = a.Flow_ID
                                  AND b.Task_ID                   = a.Task_ID
                 INNER JOIN Task_Detail c ON a.Task_ID            = c.Task_ID
                                             AND a.Task_Detail_ID = c.Task_Detail_ID
                                             AND c.User_Input     = 'SDH'
            WHERE a.Flow_Detail_Status = 'P'

            --and File_Name is null and text_content is null Em Tâm rào lại
            ;

            --1. check last task, task_seq completed--> get next step after completed
            WITH TREE_TASK
            AS (
               SELECT
                   Task_Parent,
                   F.Task_ID,
                   0 lv,
                   Flow_ID,
                   Flow_Status,
                   Seq,
                   Task_Require,
                   Seq * 100000 X_SEQ
               FROM Flow F
               WHERE Student_ID      = @Student_ID
                     AND Process_ID  = @Process_ID
                     AND Task_Parent = @task_parent
                     AND F.use_yn    = 1
               UNION ALL
               SELECT
                   F.Task_Parent,
                   F.Task_ID,
                   T.lv+1 lv,
                   F.Flow_ID,
                   F.Flow_Status,
                   F.Seq,
                   F.Task_Require,
                   T.X_SEQ+F.Seq * 100000 /((T.lv+1)* 10) X_SEQ
               FROM Flow F
                    INNER JOIN TREE_TASK T ON F.Task_Parent = T.Task_ID
               WHERE F.use_yn = 1
               )
            SELECT /*TASK_PARENT,*/
                @last_task_id = Task_ID,
                @last_flow_id = Flow_ID,
                @last_flow_status = Flow_Status --, SEQ, TASK_REQUIRE
            FROM(
                SELECT
                    Task_Parent,
                    Task_ID,
                    Flow_ID,
                    Flow_Status,
                    X_SEQ SEQ,
                    Task_Require,
                    MIN(CASE WHEN Flow_Status = 'C' THEN 10000000000 ELSE X_SEQ END) OVER () AS MIN_SEQ
                FROM TREE_TASK A
                ) A
            WHERE SEQ = MIN_SEQ;

            --print @last_flow_status
            IF(@last_flow_status <> 'C')
                BEGIN

                    --get next flow_detail after completed. and user_input ='SDH'
                    SELECT --task_detail_id, flow_detail_status, user_input,
                        @last_task_detail_id = CASE WHEN User_Input = 'SDH'
                                                         AND Flow_Detail_Status <> 'P' THEN Task_Detail_ID
                                                    ELSE 0 END
                    FROM(
                        SELECT
                            Flow_ID,
                            a.Task_ID,
                            a.Task_Detail_ID,
                            Flow_Detail_Status,
                            Task_Detail_Seq,
                            MIN(CASE WHEN Flow_Detail_Status = 'C' THEN 1000 ELSE Task_Detail_Seq END) OVER () AS MIN_SEQ,
                            User_Input
                        FROM Flow_Detail a
                             INNER JOIN Task_Detail c ON a.Task_ID            = c.Task_ID
                                                         AND a.Task_Detail_ID = c.Task_Detail_ID
                        WHERE a.Flow_ID     = @last_flow_id
                              AND a.Task_ID = @last_task_id
                        ) a
                    WHERE MIN_SEQ = Task_Detail_Seq;

                    --PRINT @last_task_detail_id
                    IF(@last_task_detail_id IS NOT NULL AND @last_task_detail_id > 0)
                        BEGIN

                            /* update 1 task detal

update flow_detail set flow_detail_status='P', [Updated_By]='auto_next_nckh',[Updated_At]=getdate()

where flow_id= @last_flow_id and task_id =@last_task_id and task_detail_id = @last_task_detail_id

;

*/

                            --update all SDH

                            --print @Task_Detail_ID

                            --PRINT @last_task_detail_id
                            IF(@Task_Detail_ID = @last_task_detail_id)
                                BEGIN

                                    --PRINT @last_task_detail_id

                                    --PRINT @last_task_detail_id
                                    UPDATE
                                        Flow_Detail
                                    SET
                                        Flow_Detail_Status = 'P',
                                        [Updated_By] = 'auto_next_nckh',
                                        [Updated_At] = GETDATE()
                                    WHERE Flow_ID     = @last_flow_id
                                          AND Task_ID = @last_task_id
                                          AND Task_Detail_ID IN(
                                                               SELECT
                                                                   Task_Detail_ID
                                                               FROM(
                                                                   SELECT
                                                                       Flow_ID,
                                                                       a.Task_ID,
                                                                       a.Task_Detail_ID,
                                                                       Flow_Detail_Status,
                                                                       Task_Detail_Seq,
                                                                       MIN(CASE WHEN Flow_Detail_Status = 'C' THEN 1000 ELSE Task_Detail_Seq END) OVER () AS MIN_SEQ,
                                                                       User_Input,
                                                                       MIN(   CASE WHEN Flow_Detail_Status <> 'C'
                                                                                        AND User_Input <> 'SDH' THEN Task_Detail_Seq
                                                                                   ELSE 1000 END
                                                                          ) OVER () AS last_SEQ
                                                                   FROM Flow_Detail a
                                                                        INNER JOIN Task_Detail c ON a.Task_ID            = c.Task_ID
                                                                                                    AND a.Task_Detail_ID = c.Task_Detail_ID
                                                                   WHERE a.Flow_ID     = @last_flow_id
                                                                         AND a.Task_ID = @last_task_id
                                                                   ) a
                                                               WHERE MIN_SEQ             <= Task_Detail_Seq
                                                                     AND Task_Detail_Seq < last_SEQ
                                                               );
                                END;
                        END;
                    SET @NOW_STATUS = dbo.CheckStatusFlow(@Student_ID, @Process_ID, @last_flow_id, @last_task_id, 0);

                    --PRINT @NOW_STATUS

                    --set @Out_Err_Loc = @Out_Err_Loc + 'last-child--CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+','+cast(@FLOW_ID as varchar)+','+cast(@TASK_ID as varchar)+','+cast(@TASK_BEGIN as varchar)+')='+@NOW_STATUS;
                    IF(@NOW_STATUS <> ' ')
                        BEGIN
                            PRINT '@NOW_STATUS '+@NOW_STATUS;
                            PRINT @Task_Detail_ID;
                            PRINT @last_task_detail_id;
                            DECLARE @user_input VARCHAR(10);
                            SET @user_input = (
                                              SELECT
                                                  User_Input
                                              FROM Task_Detail t
                                              WHERE t.Task_Detail_ID = @last_task_detail_id
                                              );
                            IF @user_input = 'SDH' BEGIN
SET @NOW_STATUS = 'P';
END;
                            UPDATE
                                Flow
                            SET
                                Flow_Status = @NOW_STATUS,
                                [Updated_By] = 'auto_next_nckh',
                                [Updated_At] = GETDATE()
                            WHERE Process_ID     = @Process_ID
                                  AND Student_ID = @Student_ID
                                  AND Flow_ID    = @last_flow_id
                                  AND Task_ID    = @last_task_id
                                  AND use_yn     = 1;
                        END;
                END;
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            SET @ERRCODE = @@ERROR;
            SET @err_location = @err_location+ERROR_MESSAGE();
            RAISERROR(@err_location, 16, 1);
            RETURN 0;
        END CATCH;
    END;