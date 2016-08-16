#include "..\..\script_macros.hpp"
/*
    File: fn_serviceChopper.sqf
    Author: Bryan "Tonic" Boardwine

    Description:
    Main functionality for the chopper service paid, to be replaced in later version.
*/
private["_serviceCost","_action","_aircraft","_ui","_progress","_cP","_pgText"];

disableSerialization;

if (life_action_inUse) exitWith {hint localize "STR_NOTF_Action"};

_serviceCost = LIFE_SETTINGS(getNumber,"service_chopper");
_aircraft = nearestObjects[getPos air_sp, ["Air"],15];

if (count _aircraft isEqualTo 0) exitWith {hint localize "STR_Service_Aircraft_NoAir"};
if (CASH < _serviceCost) exitWith {hint format[localize "STR_Service_Aircraft_NotEnough",_serviceCost]};
_aircraft = _aircraft select 0;
if (fuel _aircraft isEqualTo 1 && ([cursorTarget] call life_fnc_isDamaged) isEqualTo false) exitWith {hint localize "STR_Service_Aircraft_NotNeeded"};

life_action_inUse = true;

_action = [
    format [localize "STR_NOTF_AIR_SERVICE_PopUp",[_serviceCost] call life_fnc_numberText],
    localize "STR_NOTF_AIR_SERVICE_TITLE",
    localize "STR_Global_Yes",
    localize "STR_Global_No"
] call BIS_fnc_guiMessage;

if (_action) then {
    closeDialog 0;
    5 cutRsc ["life_progress","PLAIN",2];
    _ui = uiNamespace getVariable "life_progress";
    _progress = _ui displayCtrl 38201;
    _pgText = _ui displayCtrl 38202;
    _pgText ctrlSetText format[localize "STR_Service_Aircraft_Servicing","waiting..."];
    _progress progressSetPosition 0.01;

    for "_cP" from 0 to 100 step 1 do {
        sleep  0.2;
        _progress progressSetPosition _cP/100;
        _pgText ctrlSetText format[localize "STR_Service_Aircraft_Servicing",_cP,"%"];

        if (!alive player || !alive _aircraft || _aircraft distance air_sp > 15) exitWith {
            life_action_inUse = false;
            5 cutText ["", "PLAIN"];
            hint localize "STR_Service_Aircraft_Missing"
        };

        if (_cP isEqualTo 100) then {
            CASH = CASH - _serviceCost;
            if (!local _aircraft) then {
                [_aircraft,1] remoteExecCall ["life_fnc_setFuel",_aircraft];
            } else {
                _aircraft setFuel 1;
            };

            _aircraft setDamage 0;

            5 cutText ["","PLAIN"];
            titleText [localize "STR_Service_Aircraft_Done","PLAIN"];
        };
    };
} else {
    hint localize "STR_NOTF_ActionCancel";
    closeDialog 0;
};

life_action_inUse = false;