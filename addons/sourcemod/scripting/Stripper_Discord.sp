#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <discordWebhookAPI>
#include <Stripper>

ConVar g_cvWebhook, g_cvWebhookRetry, g_cvChannelType;
ConVar g_cvThreadName, g_cvThreadID;

public Plugin myinfo = 
{
	name = "Stripper Discord",
	author = ".Rushaway",
	description = "Stripper API for Discord",
	version = "1.1.2",
	url = ""
}

public void OnPluginStart()
{
	g_cvWebhook = CreateConVar("sm_stripper_webhook", "", "The webhook URL of your Discord channel.", FCVAR_PROTECTED);
	g_cvWebhookRetry = CreateConVar("sm_stripper_webhook_retry", "3", "Number of retries if webhook fails.", FCVAR_PROTECTED);
	g_cvChannelType = CreateConVar("sm_stripper_channel_type", "0", "Type of your channel: (1 = Thread, 0 = Classic Text channel");

	/* Thread config */
	g_cvThreadName = CreateConVar("sm_stripper_threadname", "Stripper Error Logs", "The Thread Name of your Discord forums. (If not empty, will create a new thread)", FCVAR_PROTECTED);
	g_cvThreadID = CreateConVar("sm_stripper_threadid", "0", "If thread_id is provided, the message will send in that thread.", FCVAR_PROTECTED);

	AutoExecConfig(true);
}

public void Stripper_OnErrorLogged(char[] sBuffer, int maxlen)
{
	char sWebhookURL[WEBHOOK_URL_MAX_SIZE];
	g_cvWebhook.GetString(sWebhookURL, sizeof sWebhookURL);
	if(!sWebhookURL[0])
	{
		LogError("[Stripper-Discord] No webhook found or specified.");
		return;
	}

	char sMessage[WEBHOOK_MSG_MAX_SIZE];
	char sTime[64];
	int iTime = GetTime();
	FormatTime(sTime, sizeof(sTime), "%m/%d/%Y @ %H:%M:%S", iTime);

	Format(sMessage, sizeof(sMessage), ":eyes: Error was detected @ %s```%s```", sTime, sBuffer);

	if(StrContains(sMessage, "\"") != -1)
		ReplaceString(sMessage, sizeof(sMessage), "\"", "");

	SendWebHook(sMessage, sWebhookURL);
}

stock void SendWebHook(char sMessage[WEBHOOK_MSG_MAX_SIZE], char sWebhookURL[WEBHOOK_URL_MAX_SIZE])
{
	Webhook webhook = new Webhook(sMessage);

	char sThreadID[32], sThreadName[WEBHOOK_THREAD_NAME_MAX_SIZE];
	g_cvThreadID.GetString(sThreadID, sizeof sThreadID);
	g_cvThreadName.GetString(sThreadName, sizeof sThreadName);

	bool IsThread = g_cvChannelType.BoolValue;

	if (IsThread)
	{
		if (!sThreadName[0] && !sThreadID[0])
		{
			LogError("[Stripper-Discord] Thread Name or ThreadID not found or specified.");
			delete webhook;
			return;
		}
		else
		{
			if (strlen(sThreadName) > 0)
			{
				webhook.SetThreadName(sThreadName);
				sThreadID[0] = '\0';
			}
		}
	}

	DataPack pack = new DataPack();

	if (IsThread && strlen(sThreadName) <= 0 && strlen(sThreadID) > 0)
		pack.WriteCell(1);
	else
		pack.WriteCell(0);

	pack.WriteString(sMessage);
	pack.WriteString(sWebhookURL);

	webhook.Execute(sWebhookURL, OnWebHookExecuted, pack, sThreadID);
	delete webhook;
}

public void OnWebHookExecuted(HTTPResponse response, DataPack pack)
{
	static int retries = 0;
	pack.Reset();

	bool IsThreadReply = pack.ReadCell();

	char sMessage[WEBHOOK_MSG_MAX_SIZE], sWebhookURL[WEBHOOK_URL_MAX_SIZE];
	pack.ReadString(sMessage, sizeof(sMessage));
	pack.ReadString(sWebhookURL, sizeof(sWebhookURL));

	delete pack;
	
	if ((!IsThreadReply && response.Status != HTTPStatus_OK) || (IsThreadReply && response.Status != HTTPStatus_NoContent))
	{
		if (retries < g_cvWebhookRetry.IntValue)
		{
			PrintToServer("[Stripper-Discord] Failed to send the webhook. Resending it .. (%d/%d)", retries, g_cvWebhookRetry.IntValue);
			SendWebHook(sMessage, sWebhookURL);
			retries++;
			return;
		}
		else
		{
			LogError("[Stripper-Discord] Failed to send the webhook after %d retries, aborting.", retries);
			LogError("[Stripper-Discord] Failed message : %s", sMessage);
		}
	}
	retries = 0;
}