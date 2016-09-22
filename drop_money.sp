#pragma semicolon 1
#include <sdktools>
#pragma newdecls required

#define MONEY_MODEL "models/props/cs_assault/money.mdl"

bool g_bPressedUse[MAXPLAYERS + 1];
float g_flPressUse[MAXPLAYERS + 1];

public Plugin myinfo = {
	author = "Hikka",
	description = "Выкидываем нужную сумму денег.",
	version = "0.2",
};

public void OnPluginStart() {
	RegConsoleCmd("sm_drop_money", sm_dropmoney, "!drop_money <сумма>");
	RegConsoleCmd("sm_dropmoney", sm_dropmoney, "!dropmoney <сумма>");
}

public void OnMapStart() {
	PrecacheModel(MONEY_MODEL, true);
}

public Action sm_dropmoney(int client, int args) {
	if (client && IsClientInGame(client) && IsPlayerAlive(client)) {
		if (args != 1) {
			ReplyToCommand(client, "Используй: sm_dropmoney <сумма> или sm_drop_money <сумма>");
			return Plugin_Handled;
		}
		
		int ply_money = GetEntProp(client, Prop_Send, "m_iAccount");
		
		char arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		int amount = StringToInt(arg);
		
		if (ply_money > 0) {
			if (amount > 0) {
				if (amount > ply_money) amount = ply_money;
				SetEntProp(client, Prop_Send, "m_iAccount", ply_money - amount);
				Drop_Money(client, amount);
				PrintHintText(client, "Выкинул $%d", amount);
			}
			
			else if (amount < 1 || amount > ply_money) PrintHintText(client, "Некорректная сумма, на счету $%d", ply_money);
		} else PrintHintText(client, "У тебя нет денег!");
	}
	return Plugin_Handled;
}

bool Drop_Money(int client, int amount) {
	int ent;
	if((ent = CreateEntityByName("prop_physics")) != -1) {
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
		return true;
	}
	return false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3]){
	if (!IsClientInGame(client)) return Plugin_Handled;
	
	if (IsPlayerAlive(client)){
		if (buttons & IN_USE && g_bPressedUse[client] == false) {
			g_bPressedUse[client] = true;
			g_flPressUse[client] = GetGameTime();
		} 
		else if (!(buttons & IN_USE) && g_bPressedUse[client] == true) {
			g_bPressedUse[client] = false;
			if ((GetGameTime() - g_flPressUse[client]) < 0.2){
				int ent = AimTargetProp(client);
				if (ent != -1 && IsValidEntity(ent)) {
					char modelname[128];
					GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
					
					if (strcmp(modelname, MONEY_MODEL) == 0) {
						float origin[3], clientent[3];
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origin);
						GetClientAbsOrigin(client, clientent);
						float distance = GetVectorDistance(origin, clientent);
						if (distance <= 100) {
							char amount[32];
							GetEntPropString(ent, Prop_Data, "m_iName", amount, sizeof(amount));
							if (0 < StringToInt(amount)) {
								RemoveEdict(ent);
								SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") + StringToInt(amount));
								PrintToChat(client, "Ты поднял \x04$%d", StringToInt(amount));
								return Plugin_Handled;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client) {
	g_bPressedUse[client] = false;
	g_flPressUse[client] = -1.0;
}

stock int AimTargetProp(int client) {
    float m_vecOrigin[3],
          m_angRotation[3];
 
    GetClientEyePosition(client, m_vecOrigin);
    GetClientEyeAngles(client, m_angRotation);
 
    Handle tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
    if (TR_DidHit(tr)) {
        int pEntity = TR_GetEntityIndex(tr);
        if (MaxClients < pEntity) {
            delete tr;
            return pEntity;
        }
    }
 
    delete tr;
    return -1;
}
 
public bool TRDontHitSelf(int entity, int mask, any data) {
    return !(entity == data);
}