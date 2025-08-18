<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_approvers</fullName>
        <description>Notify approvers</description>
        <protected>false</protected>
        <recipients>
            <recipient>Product_Recall</recipient>
            <type>group</type>
        </recipients>
        <senderAddress>cssfnoreply@spectrumbrands.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_Recall_Case_Approvers</template>
    </alerts>
    <alerts>
        <fullName>Notify_submitter</fullName>
        <description>Notify submitter</description>
        <protected>false</protected>
        <recipients>
            <field>SuppliedEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>cssfnoreply@spectrumbrands.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_Recall_Case_Submitter</template>
    </alerts>
    <alerts>
        <fullName>Send_Email_for_Rejection_of_Refund_Request</fullName>
        <description>Send Email for Rejection of Refund Request</description>
        <protected>false</protected>
        <recipients>
            <field>SuppliedEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>cssfnoreply@spectrumbrands.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_Recall_Case_Rejection</template>
    </alerts>
    <alerts>
        <fullName>X2_Second_Contact_questions_Reminder</fullName>
        <description>2 Second Contact questions Reminder</description>
        <protected>false</protected>
        <recipients>
            <field>ContactEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>tristarcustomerservice@tristarproductsinc.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/X2nd_follow_up_template</template>
    </alerts>
    <alerts>
        <fullName>X3_Third_contact_email</fullName>
        <description>3 Third contact email</description>
        <protected>false</protected>
        <recipients>
            <field>ContactEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>tristarcustomerservice@tristarproductsinc.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/X3rd_reminder_email_template12</template>
    </alerts>
    <fieldUpdates>
        <fullName>Check_Refund_Refund_Approved</fullName>
        <field>Is_Refund_Request_Approved__c</field>
        <literalValue>1</literalValue>
        <name>Check Refund Refund Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Incident_Stages_Waiting_on_Customer</fullName>
        <field>custom_incident_stages__c</field>
        <literalValue>Waiting on CM-Final</literalValue>
        <name>&quot;Incident Stages&quot;-&quot;Waiting on Customer&quot;</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Case_Status_to_Close</fullName>
        <field>Status</field>
        <literalValue>Refund Rejected</literalValue>
        <name>Update Case Status to Close</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>add_7_days_to_followup_date</fullName>
        <field>Follow_Up_Date__c</field>
        <formula>Follow_Up_Date__c +7</formula>
        <name>add 7 days to followup date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>add_7_days_to_followup_date_for_3rd</fullName>
        <field>Follow_Up_Date__c</field>
        <formula>Follow_Up_Date__c +7</formula>
        <name>add 7 days to followup date for 3rd</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>stage_equal_to_followup_3</fullName>
        <field>custom_incident_stages__c</field>
        <literalValue>Ctc Attempt 3</literalValue>
        <name>stage equal to followup 3</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>2nd Test workflow for reminder</fullName>
        <actions>
            <name>X2_Second_Contact_questions_Reminder</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>add_7_days_to_followup_date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>stage_equal_to_followup_3</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.Follow_date_is_today__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.custom_incident_stages__c</field>
            <operation>equals</operation>
            <value>Ctc attempt 2</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Pending</value>
        </criteriaItems>
        <failedMigrationToolVersion>238.14.6</failedMigrationToolVersion>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>3rd reminder test</fullName>
        <actions>
            <name>X3_Third_contact_email</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Incident_Stages_Waiting_on_Customer</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>add_7_days_to_followup_date_for_3rd</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.Follow_date_is_today__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Pending</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.custom_incident_stages__c</field>
            <operation>equals</operation>
            <value>Ctc Attempt 3</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
