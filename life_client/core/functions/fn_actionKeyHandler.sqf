#include "..\..\script_macros.hpp"
/*
    File: fn_actionKeyHandler.sqf
    Author: Bryan "Tonic" Boardwine

    Description:
    Master action key handler, handles requests for picking up various items and
    interacting with other players (Cops = Cop Menu for unrestrain,escort,stop escort, arrest (if near cop hq), etc).
*/
private["_curObject","_isWater","_CrateModelNames","_crate","_fish","_animal","_whatIsIt","_handle","_swimmingAnimations","_isVehicle","_miscItems","_money","_list","_time"];

if (life_action_inUse) exitWith {}; //Action is in use, exit to prevent spamming.
if (life_interrupted) exitWith {life_interrupted = false};
if (dialog) exitWith {}; //Don't bother when a dialog is open.
if (vehicle player != player) exitWith {}; //He's in a vehicle, cancel!

_time = time;
_curObject = cursorObject;
_list = ["landVehicle","Ship","Air"];
_isVehicle = if (KINDOF_ARRAY(_curObject,_list)) then {true} else {false};
_miscItems = ["Land_BottlePlastic_V1_F","Land_TacticalBacon_F","Land_Can_V3_F","Land_CanisterFuel_F","Land_Suitcase_F"];

//This ensures that the player is in the water and swimming
_swimmingAnimations = ["aswmpercmstpsnonwnondnon","aswmpercmstpsnonwnondnon_aswmpercmrunsnonwnondf","aswmpercmrunsnonwnondf","abswpercmrunsnonwnondf","abswpercmsprsnonwnondf","abswpercmrunsnonwnondl","abswpercmrunsnonwnondb","abswpercmwlksnonwnondb","abswpercmstpsnonwnondnon","abswpercmstpsnonwnondnon_abswpercmrunsnonwnondf","abswpercmstpsnonwnondnon_godown","abswpercmstpsnonwnondnon_goup","aswmpercmstpsnonwnondnon_goup","aswmpercmrunsnonwnondl","abswpercmwlksnonwnondl","abswpercmrunsnonwnondr","abswpercmwlksnonwnondr","abswpercmwlksnonwnondfr","aswmpercmwlksnonwnondfr","aswmpercmwlksnonwnondf","aswmpercmwlksnonwnondfl","aswmpercmrunsnonwnondb","aswmpercmwlksnonwnondb","aswmpercmrunsnonwnondr","abswpercmwlksnonwnondf","aswmpercmsprsnonwnondf","asswpercmstpsnonwnondnon"];

_isWater = false;

if (surfaceIsWater (visiblePositionASL player)) then {
    _isWater =  AnimationState player in _swimmingAnimations;
};

//Handle COP menu while escorting
if (player getVariable ["isEscorting",false]) exitWith {
    [] call life_fnc_copInteractionMenu;
};

//Handle COP menu
if (isPlayer _curObject && _curObject isKindOf "Man") then {
    if ((_curObject getVariable ["restrained",false]) && !dialog && playerSide isEqualTo west) exitWith {
        [_curObject] call life_fnc_copInteractionMenu;
    };
};

//Handle ATM interaction
if (LIFE_SETTINGS(getNumber,"global_ATM") isEqualTo 1) then {
    if ((call life_fnc_nearATM) && {!dialog}) exitWith {
        [] call life_fnc_atmMenu;
    };
};

//Handle Reviving
if (_curObject isKindOf "Man" && !(_curObject isKindOf "Animal") && {!alive _curObject} && !(_curObject getVariable ["Revive",false]) && {playerSide in [west,independent]}) exitWith {
    //Hotfix code by ins0
    if (((playerSide isEqualTo west && {(LIFE_SETTINGS(getNumber,"revive_cops") isEqualTo 1)}) || playerSide isEqualTo independent)) then {
        if (life_inv_defibrillator > 0) then {
            [_curObject] call life_fnc_revivePlayer;
        };
    };
};

//Handle Mics items
if ((typeOf _curObject) in _miscItems) exitWith {
    [_curObject,player,false] remoteExecCall ["TON_fnc_pickupAction",RSERV];
};

//Handle money pickup
if ((typeOf _curObject) isEqualTo "Land_Money_F" && {!(_curObject getVariable ["inUse",false])}) exitWith {
    [_curObject,player,true] remoteExecCall ["TON_fnc_pickupAction",RSERV];
};

//Handle vehicle interaction
if (_isVehicle) then {
    if (!dialog) then {
        if (player distance _curObject < ((boundingBox _curObject select 1) select 0)+2 && (!(player getVariable ["restrained",false])) && (!(player getVariable ["playerSurrender",false])) && !life_isknocked && !life_istazed) exitWith {
            [_curObject] call life_fnc_vInteractionMenu;
        };
    };
};

//Handle container menu
if ((_curObject isKindOf "B_supplyCrate_F" || _curObject isKindOf "Box_IND_Grenades_F") && {player distance _curObject < 3} ) exitWith {
    if (alive _curObject) then {
        [_curObject] call life_fnc_containerMenu;
    };
};

//Handle housing
if (_curObject isKindOf "House_F" && {player distance _curObject < 12} || ((nearestObject [[16019.5,16952.9,0],"Land_Dome_Big_F"]) == _curObject || (nearestObject [[16019.5,16952.9,0],"Land_Research_house_V1_F"]) == _curObject)) exitWith {
    [_curObject] call life_fnc_houseMenu;
};

//Handle Fishing and Hunting
if (_isWater) then {
    _fish = (nearestObjects[player,(LIFE_SETTINGS(getArray,"animaltypes_fish")),3]) select 0;
    if (!isNil "_fish") then {
        if (!alive _fish) exitWith {
            [_fish] call life_fnc_catchFish;
        };
    };
} else {
    _animal = (nearestObjects[player,(LIFE_SETTINGS(getArray,"animaltypes_hunting")),3]) select 0;
    if (!isNil "_animal") then {
        if (!alive _animal) exitWith {
            [_animal] call life_fnc_gutAnimal;
        };
    };
};

//Handle normal resourse gathering and mining
if (playerSide isEqualTo civilian) then {
    _whatIsIt = [] call life_fnc_whereAmI;
    if (life_action_gathering) exitWith {};
    switch (_whatIsIt) do {
        case "mine"     :   { _handle = [] spawn life_fnc_mine };
        case "resource" :   { _handle = [] spawn life_fnc_gather };
        default             { _handle = 0 spawn {}};
    };
    life_action_gathering = true;
    waitUntil {scriptDone _handle};
    life_action_gathering = false;
};

//Temp fail safe.
if(life_action_inUse) then {
    [] spawn {
        sleep 60;
        life_action_inUse = false;
    };
};