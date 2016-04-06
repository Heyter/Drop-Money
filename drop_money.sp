#pragma semicolon 1
#include <sdktools>

#pragma newdecls required

#define MONEY_MODEL "models/props/cs_assault/money.mdl"

int money[MAXPLAYERS + 1];

public Plugin myinfo =
{
	author = "Hejter (HLmod.ru)",
	description = "Выкидываем нужную сумму денег.",
	version = "0.1",
	url = "HLmod.ru",
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_drop_money", Command_DMoney, "!drop_money <сумма>");
}

public void OnMapStart()
{
	PrecacheModel(MONEY_MODEL, true);
}

public Action Command_DMoney(int client, int args)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (args == 1)
		{
			int MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			money[client] = GetEntData(client, MoneyOffset, 4);
			int money_set = GetEntProp(client, Prop_Send, "m_iAccount");
			
			char arg[64];
			GetCmdArg(1, arg, sizeof(arg));
			int amount = StringToInt(arg);
			
			if (money[client] > 0)
			{
				if (amount > 0)
				{
					if (amount > money[client]) amount = money[client];
					SetEntProp(client, Prop_Send, "m_iAccount", money_set - amount);
					Drop_Money(client, amount);
					PrintHintText(client, "Выкинул %d$", amount);
				}
				
				else if (amount < money[client] || amount == money[client]) PrintHintText(client, "Сумма должна быть не меньше 1$");
				else if (!amount) PrintHintText(client, "Неправильная сумма!");
				else if (amount > money[client]) PrintHintText(client, "Сумма не может быть больше наличных!");
				else if (amount < 0 || amount == 0) PrintHintText(client, "Сумма должна быть не меньше 1$");
			}
			else PrintHintText(client, "У тебя нет денег!");
		}
		else ReplyToCommand(client, "Используй: sm_drop_money <сумма>");
	}
	return Plugin_Handled;
}

void Drop_Money(int client, int amount)
{
	int ent;
	if((ent = CreateEntityByName("prop_physics")) != -1)
	{
		float origin[3];
		GetClientEyePosition(client, origin);
		
		TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
		
		char TargetName[32];
		Format(TargetName, sizeof(TargetName), "%i", amount);
		
		DispatchKeyValue(ent, "model", MONEY_MODEL);
		DispatchKeyValue(ent, "physicsmode", "2");
		DispatchKeyValue(ent, "massScale", "8.0");
		DispatchKeyValue(ent, "targetname", TargetName);
		DispatchSpawn(ent);
		
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
		
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3]){
	if(!IsClientInGame(client)) return;
	
	if(buttons & IN_USE)
	{
		if(IsPlayerAlive(client))
		{ 
			int Ent;
			char Classname[32];
		   
			Ent = GetClientAimTarget(client, false);
		   
			if (Ent != -1 && IsValidEntity(Ent))
			{
				float origin[3];
				float clientent[3];
			   
				GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", origin);
				GetClientAbsOrigin(client, clientent);
			   
				float distance = GetVectorDistance(origin, clientent);
				if (distance < 100)
				{
					GetEdictClassname(Ent, Classname, sizeof(Classname));
				   
					char modelname[128];
					GetEntPropString(Ent, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
				   
					if (StrEqual(modelname, MONEY_MODEL))
					{
						char amount[32];
						GetTargetName(Ent, amount, sizeof(amount));
						
						int money_set = GetEntProp(client, Prop_Send, "m_iAccount");
						
						if (0 < StringToInt(amount))
						{
							RemoveEdict(Ent);
							SetEntProp(client, Prop_Send, "m_iAccount", money_set + StringToInt(amount));
							PrintToChat(client, "Ты поднял %d$", StringToInt(amount));
						}	
					}
				}
			}
		}
	}
}

void GetTargetName(int entity, char[] buffer, int maxlen)
{
	GetEntPropString(entity, Prop_Data, "m_iName", buffer, maxlen);
}