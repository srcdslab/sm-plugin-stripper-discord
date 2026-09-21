#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <discordWebhookAPI>
#include <Stripper>

ConVar g_cvWebhook, g_cvWebhookRetry;
ConVar g_cvThreadName, g_cvThreadID, g_cvUserName, g_cvAvatar;

public Plugin myinfo = 
{
	name = "Stripper Discord",
	author = ".Rushaway",
	description = "Stripper API for Discord",
	version = "1.2.0",
	url = ""
}

public void OnPluginStart()
{
	g_cvWebhook = CreateConVar("sm_stripper_webhook", "", "The webhook URL of your Discord channel.", FCVAR_PROTECTED);
	g_cvWebhookRetry = CreateConVar("sm_stripper_webhook_retry", "3", "Number of retries if webhook fails.", FCVAR_PROTECTED);

	/* Thread config */
	g_cvThreadName = CreateConVar("sm_stripper_threadname", "Stripper Error Logs", "The Thread Name of your Discord forums. (If not empty, will create a new thread)", FCVAR_PROTECTED);
	g_cvThreadID = CreateConVar("sm_stripper_threadid", "0", "If thread_id is provided, the message will send in that thread.", FCVAR_PROTECTED);
	g_cvUserName = CreateConVar("sm_stripper_username", "Stripper", "The username of the Discord bot.", FCVAR_PROTECTED);
	g_cvAvatar = CreateConVar("sm_stripper_avatar", "https://avatars.githubusercontent.com/u/110772618?s=200&v=4", "The avatar URL of the Discord bot.", FCVAR_PROTECTED);

	AutoExecConfig(true);
}

public void Stripper_OnErrorLogged(const char[] sBuffer)
{
	char sWebhookURL[WEBHOOK_URL_MAX_SIZE];
	g_cvWebhook.GetString(sWebhookURL, sizeof sWebhookURL);
	if (!sWebhookURL[0])
	{
		LogError("[Stripper-Discord] No webhook found or specified.");
		return;
	}

	char sMessage[WEBHOOK_MSG_MAX_SIZE];
	char sTime[64];
	int iTime = GetTime();
	FormatTime(sTime, sizeof(sTime), "%m/%d/%Y @ %H:%M:%S", iTime);

	Format(sMessage, sizeof(sMessage), ":eyes: Error was detected @ %s```%s```", sTime, sBuffer);

	if (StrContains(sMessage, "\"") != -1)
		ReplaceString(sMessage, sizeof(sMessage), "\"", "");

	SendWebHook(sMessage, sWebhookURL);
}

stock void SendWebHook(char sMessage[WEBHOOK_MSG_MAX_SIZE], char sWebhookURL[WEBHOOK_URL_MAX_SIZE], int retries = 0)
{
	Webhook webhook = new Webhook(sMessage);

	char sThreadID[32], sThreadName[WEBHOOK_THREAD_NAME_MAX_SIZE];
	char sUserName[256], sAvatar[256];

	g_cvThreadID.GetString(sThreadID, sizeof sThreadID);
	g_cvThreadName.GetString(sThreadName, sizeof sThreadName);
	g_cvUserName.GetString(sUserName, sizeof sUserName);
	g_cvAvatar.GetString(sAvatar, sizeof sAvatar);

	/* Webhook Avatar */
	if (strlen(sAvatar) > 0)
		webhook.SetAvatarURL(sAvatar);

	/* Webhook Username */
	if (strlen(sUserName) > 0)
		webhook.SetUsername(sUserName);

	/* Webhook Thread Name */
	if (strlen(sThreadName) > 0)
		webhook.SetThreadName(sThreadName);

	DataPack pack = new DataPack();

	pack.WriteString(sMessage);
	pack.WriteString(sWebhookURL);
	pack.WriteCell(retries);

	webhook.Execute(sWebhookURL, OnWebHookExecuted, pack, sThreadID);
	delete webhook;
}

public void OnWebHookExecuted(HTTPResponse response, DataPack pack)
{
	pack.Reset();

	char sMessage[WEBHOOK_MSG_MAX_SIZE], sWebhookURL[WEBHOOK_URL_MAX_SIZE];
	pack.ReadString(sMessage, sizeof(sMessage));
	pack.ReadString(sWebhookURL, sizeof(sWebhookURL));
	int retries = pack.ReadCell();

	delete pack;

	if (response.Status != HTTPStatus_OK && response.Status != HTTPStatus_NoContent)
	{
		if (retries < g_cvWebhookRetry.IntValue)
		{
			PrintToServer("[Stripper-Discord] Failed to send the webhook (HTTP %d). Resending it .. (%d/%d)", view_as<int>(response.Status), retries + 1, g_cvWebhookRetry.IntValue);
			SendWebHook(sMessage, sWebhookURL, retries + 1);
			return;
		}
		else
		{
			LogError("[Stripper-Discord] Failed to send the webhook after %d retries  (last HTTP status: %d), aborting.", retries, view_as<int>(response.Status));
			LogError("[Stripper-Discord] Failed message : %s", sMessage);
		}
	}
}
