public Plugin:myinfo = {
	name = "[Cs:s]Teammate attack show all",
	author = "Bacardi",
	description = "Show all players team attacker in chat",
	version = "0.5",
	url = "http://forums.alliedmods.net/showthread.php?t=171252"
};

new Handle:mp_friendlyfire = INVALID_HANDLE;

public OnPluginStart()
{
	if((mp_friendlyfire = FindConVar("mp_friendlyfire")) == INVALID_HANDLE)
	{
		SetFailState("Missing mp_friendlyfire");
	}
	HookConVarChange(mp_friendlyfire, convar_change);

	LoadTranslations("teamattack_show_all.phrases");

	if(GetConVarBool(mp_friendlyfire))
	{
		convar_change(mp_friendlyfire, "0", "1");
	}
}

public convar_change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == mp_friendlyfire)
	{
		new bool:oldv, bool:friendlyfire;
		oldv = StringToInt(oldValue) != 0;

		if((friendlyfire = GetConVarBool(mp_friendlyfire)) != oldv)
        {
			if(friendlyfire)
			{
				HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
			}
			else
			{
				UnhookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
			}
		}
	}
}

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(!reliable)
	{
		return Plugin_Continue;
	}
	new String:buffer[100];

	if (GetUserMessageType() == UM_Protobuf)
	{
		PbReadString(bf, "params", buffer, sizeof(buffer), 0);

		if(PbReadInt(bf, "msg_dst") == 3 && StrContains(buffer, "Game_teammate_attack") != -1)
		{
			PbReadString(bf, "params", buffer, sizeof(buffer), 1);
			new String:name[MAX_NAME_LENGTH];
			GetClientName(players[0], name, sizeof(name));

			if(StrEqual(buffer, name))
			{
				new Handle:pack;
				CreateDataTimer(0.01, msg, pack);
				WritePackCell(pack, GetClientUserId(players[0]));
			}
			return Plugin_Handled;
		}
	}
	else
	{
		BfReadString(bf, buffer, sizeof(buffer), false); // Message
		if(StrContains(buffer, "Game_teammate_attack") != -1) // Message match
		{
			BfReadString(bf, buffer, sizeof(buffer), false); // Get name
			new String:name[MAX_NAME_LENGTH];
			GetClientName(players[0], name, sizeof(name)); // Get name of player who get this usermsg

			if(StrEqual(buffer, name)) // Team attacker name match player name who get this usermsg.
			{
				new Handle:pack;
				CreateDataTimer(0.01, msg, pack); // Print new message after this usermessage
				WritePackCell(pack, GetClientUserId(players[0])); // Let's take player #userid
			}
			return Plugin_Handled; // Stop show message
		}
	}

	return Plugin_Continue;
}

public Action:msg(Handle:timer, Handle:pack)
{
	new client;
	ResetPack(pack);
	client = ReadPackCell(pack); // This is now #userid

	if((client = GetClientOfUserId(client)) != 0) // Find player with that #userid, is it still in game ?
	{
		new String:buffer[128], Handle:hBf;

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				hBf = StartMessageOne("SayText2", i);
				if (hBf != INVALID_HANDLE)
				{
					if (GetUserMessageType() == UM_Protobuf)
					{
						Format(buffer, sizeof(buffer), " %T", "teammate attack", i, "\x03", client, "\x01"); // Make new message with translations
						PbSetInt(hBf, "ent_idx", client);
						PbSetBool(hBf, "chat", true);
						PbSetString(hBf, "msg_name", "Cstrike_Chat_All");

						PbAddString(hBf, "params", "[SM] ");
						PbAddString(hBf, "params", buffer);
						PbAddString(hBf, "params", "");
						PbAddString(hBf, "params", "");
						//PbAddString(hBf, "params", "");

						PbSetBool(hBf, "textallchat", true);
					}
					else
					{
						Format(buffer, sizeof(buffer), "\x01[SM] %T", "teammate attack", i, "\x03", client, "\x01"); // Make new message with translations
						BfWriteByte(hBf, client);
						BfWriteByte(hBf, 0);
						BfWriteString(hBf, buffer);
					}

					EndMessage();
				}
			}
		}
	}
}