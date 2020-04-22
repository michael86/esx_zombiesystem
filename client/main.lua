ESX = nil
players = {}
entitys = {}

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end
end)

if Config.NotHealthRecharge then
  SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
end

if Config.MuteAmbience then
  StartAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
end

SetBlackout(Config.Blackout)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent("esx_zombiesystem:playerupdate")
AddEventHandler("esx_zombiesystem:playerupdate", function(mPlayers)
  players = mPlayers
end)

TriggerServerEvent("RegisterNewZombie")
TriggerServerEvent("esx_zombiesystem:newplayer", PlayerId())

RegisterNetEvent("ZombieSync")
AddEventHandler("ZombieSync", function()
  
  AddRelationshipGroup("zombie")
  SetRelationshipBetweenGroups(0, GetHashKey("zombie"), GetHashKey("PLAYER"))
  SetRelationshipBetweenGroups(2, GetHashKey("PLAYER"), GetHashKey("zombie"))
  
  while true do
    Citizen.Wait(1)
    if #entitys < Config.SpawnZombie then
      
      x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
      
      EntityModel = Config.Models[math.random(1, #Config.Models)]
      EntityModel = string.upper(EntityModel)
      RequestModel(GetHashKey(EntityModel))

      while not HasModelLoaded(GetHashKey(EntityModel)) or not HasCollisionForModelLoaded(GetHashKey(EntityModel)) do
        Wait(1)
      end
      
      local posX = x
      local posY = y
      local posZ = z + 999.0
      
      repeat
        Wait(1)
        
        posX = x + math.random(-Config.MaxSpawnDistance, Config.MaxSpawnDistance)
        posY = y + math.random(-Config.MaxSpawnDistance, Config.MaxSpawnDistance)
        
        _,posZ = GetGroundZFor_3dCoord(posX+.0,posY+.0,z,1)
        
        for _, player in pairs(players) do
          Wait(1)
          playerX, playerY = table.unpack(GetEntityCoords(GetPlayerPed(player), true))
          if posX > playerX - Config.MinSpawnDistance and posX < playerX + Config.MinSpawnDistance or posY > playerY - Config.MinSpawnDistance and posY < playerY + Config.MinSpawnDistance then
            canSpawn = false
            break
          else
            canSpawn = true
          end
        end
      until canSpawn

      entity = CreatePed(4, GetHashKey(EntityModel), posX, posY, posZ, 0.0, true, false)
      
      walk = Config.Walks[math.random(1, #Config.Walks)]
      
      --! Works, but can push the ms up if zombie spawn rate is high.
      -- Citizen.CreateThread(function()
      --   play_anim_sequence('zombie_walk', entity)
      -- end)

      RequestAnimSet(walk)
      while not HasAnimSetLoaded(walk) do
        Citizen.Wait(1)
      end

      SetPedMovementClipset(entity, walk, 1.0)
      
      TaskGoToEntity(entity, GetPlayerPed(-1), -1, 0.0, 1.0, 1073741824, 0)
      SetCanAttackFriendly(entity, true, true)
      SetPedCanEvasiveDive(entity, false)
      SetPedRelationshipGroupHash(entity, GetHashKey("zombie"))
      SetPedCombatAbility(entity, 0)
      SetPedCombatRange(entity,0)
      SetPedCombatMovement(entity, 0)
      SetPedAlertness(entity,0)
      SetPedIsDrunk(entity, true)
      SetPedConfigFlag(entity,100,1)
      ApplyPedDamagePack(entity,"BigHitByVehicle", 0.0, 9.0)
      ApplyPedDamagePack(entity,"SCR_Dumpster", 0.0, 9.0)
      ApplyPedDamagePack(entity,"SCR_Torture", 0.0, 9.0)
      DisablePedPainAudio(entity, true)
      StopPedSpeaking(entity,true)
      SetEntityAsMissionEntity(entity, true, true)
      
      if not NetworkGetEntityIsNetworked(entity) then
        NetworkRegisterEntityAsNetworked(entity)
      end
      
      table.insert(entitys, entity)
    end	
    
    for i, entity in pairs(entitys) do

      if not DoesEntityExist(entity) then
        SetEntityAsNoLongerNeeded(entity)
        table.remove(entitys, i)
      else

        local playerX, playerY, playerZ = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
        local pedX, pedY, pedZ = table.unpack(GetEntityCoords(entity, true))	
        
        if pedX < playerX - Config.DespawnDistance or pedX > playerX + Config.DespawnDistance or pedY < playerY - Config.DespawnDistance or pedY > playerY + Config.DespawnDistance then
          local model = GetEntityModel(entity)
          SetEntityAsNoLongerNeeded(entity)
          SetModelAsNoLongerNeeded(model)
          table.remove(entitys, i)
        end
      end
      
      if IsEntityInWater(entity) then
        local model = GetEntityModel(entity)
        SetEntityAsNoLongerNeeded(entity)
        SetModelAsNoLongerNeeded(model)
        DeleteEntity(entity)
        table.remove(entitys,i)
      end
    end
  end
end)

Citizen.CreateThread(function()

  while true do
    Citizen.Wait(1)
    
    for i, entity in pairs(entitys) do
      
      playerX, playerY, playerZ = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
      pedX, pedY, pedZ = table.unpack(GetEntityCoords(entity, true))
      
      if IsPedDeadOrDying(entity, 1) ~= 1 then

        if(Vdist(playerX, playerY, playerZ, pedX, pedY, pedZ) < 0.6)then

          if IsPedRagdoll(entity, 1) ~= 1 then

            if not IsPedGettingUp(entity) then

              RequestAnimDict("special_ped@zombie@monologue_5@monologue_5d")
              TaskPlayAnim(entity,"special_ped@zombie@monologue_5@monologue_5d","brainsitsbrains_3",1.0, 1.0, 500, 9, 1.0, 0, 0, 0)

              local playerPed = GetPlayerPed(-1)
              local maxHealth = GetEntityMaxHealth(playerPed)
              local health = GetEntityHealth(playerPed)
              local newHealth = math.min(maxHealth, math.floor(health - maxHealth / 8))

              SetEntityHealth(playerPed, newHealth)
              Wait(2000)	
              TaskGoToEntity(entity, GetPlayerPed(-1), -1, 0.0, 1.0, 1073741824, 0)
              
            end
          end
        end
      end
    end
  end
end)

if Config.ZombieDropLoot then
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(1)
      for i, entity in pairs(entitys) do
        playerX, playerY, playerZ = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
        pedX, pedY, pedZ = table.unpack(GetEntityCoords(entity, true))
        if DoesEntityExist(entity) == false then
          table.remove(entitys, i)
        end
        if IsPedDeadOrDying(entity, 1) == 1 then
          if GetPedSourceOfDeath(entity) == PlayerPedId() then
            playerX, playerY, playerZ = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
            pedX, pedY, pedZ = table.unpack(GetEntityCoords(entity, true))	
            if not IsPedInAnyVehicle(PlayerPedId(), false) then
              if(Vdist(playerX, playerY, playerZ, pedX, pedY, pedZ) < 1.5) then
                DrawText3D({x = pedX, y = pedY, z = pedZ + 0.2}, '~c~PRESS ~b~[E]~c~ TO SEARCH', 0.8, 4)
                if IsControlJustReleased(1, 51) then
                  if DoesEntityExist(GetPlayerPed(-1)) then
                    RequestAnimDict("random@domestic")
                    while not HasAnimDictLoaded("random@domestic") do
                      Citizen.Wait(1)
                    end
                    TaskPlayAnim(PlayerPedId(), "random@domestic", "pickup_low", 8.0, -8, 2000, 2, 0, 0, 0, 0)
                    
                    randomChance = math.random(1, 100)
                    randomLoot = Config.WeaponLoot[math.random(1, #Config.WeaponLoot)]
                    
                    Citizen.Wait(2000)
                    if randomChance > 0 and randomChance < Config.ProbabilityWeaponLoot then
                      local randomAmmo = math.random(1, 30)
                      GiveWeaponToPed(PlayerPedId(), randomLoot, randomAmmo, true, false)
                      exports.pNotify:SendNotification({text = 'You found ' .. randomLoot, type = "success", timeout = 2500, layout = "centerRight", queue = "right"})
                    elseif randomChance >= Config.ProbabilityWeaponLoot and randomChance < Config.ProbabilityMoneyLoot then
                      TriggerServerEvent('esx_zombiesystem:moneyloot')
                    elseif randomChance >= Config.ProbabilityMoneyLoot and randomChance < 100 then
                      exports.pNotify:SendNotification({text = 'You not found nothing', type = "error", timeout = 2500, layout = "centerRight", queue = "right"})
                    end
                    ClearPedSecondaryTask(GetPlayerPed(-1))
                    local model = GetEntityModel(entity)
                    SetEntityAsNoLongerNeeded(entity)
                    SetModelAsNoLongerNeeded(model)
                    table.remove(entitys, i)
                  end
                end
              end
            end
          end
        end
      end
    end
  end)
end

if Config.SafeZoneRadioBlip then
  blip = AddBlipForRadius(Config.SafeZoneCoords.x, Config.SafeZoneCoords.y, Config.SafeZoneCoords.z, Config.SafeZoneCoords.radio)
  SetBlipHighDetail(blip, true)
  SetBlipColour(blip, 2)
  SetBlipAlpha (blip, 128)
end

if Config.SafeZone then
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(1)
      for i, entity in pairs(entitys) do
        pedX, pedY, pedZ = table.unpack(GetEntityCoords(entity, true))
        if(Vdist(pedX, pedY, pedZ, Config.SafeZoneCoords.x, Config.SafeZoneCoords.y, Config.SafeZoneCoords.z) < Config.SafeZoneCoords.radio)then
          Citizen.Trace("Zombie Eliminated from refuge\n")
          SetEntityHealth(entity, 0)
          SetEntityAsNoLongerNeeded(entity)
          DeleteEntity(entity)
          table.remove(entitys, i)
        end
      end
    end
  end)
end

RegisterNetEvent('esx_zombiesystem:clear')
AddEventHandler('esx_zombiesystem:clear', function()
  for i, entity in pairs(entitys) do
    local model = GetEntityModel(entity)
    SetEntityAsNoLongerNeeded(entity)
    SetModelAsNoLongerNeeded(model)
    table.remove(entitys, i)
    --Citizen.Trace("Zombie Eliminated\n")
  end
end)

if Config.Debug then
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(1)
      for i, entity in pairs(entitys) do
        local playerX, playerY, playerZ = table.unpack(GetEntityCoords(PlayerPedId(), true))
        local pedX, pedY, pedZ = table.unpack(GetEntityCoords(entity, false))	
        DrawLine(playerX, playerY, playerZ, pedX, pedY, pedZ, 250,0,0,250)
      end
    end
  end)
end

if Config.NoPeds then
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(1)
      SetVehicleDensityMultiplierThisFrame(0.0)
      SetPedDensityMultiplierThisFrame(0.0)
      SetRandomVehicleDensityMultiplierThisFrame(0.0)
      SetParkedVehicleDensityMultiplierThisFrame(0.0)
      SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
      local playerPed = GetPlayerPed(-1)
      local pos = GetEntityCoords(playerPed) 
      RemoveVehiclesFromGeneratorsInArea(pos['x'] - 500.0, pos['y'] - 500.0, pos['z'] - 500.0, pos['x'] + 500.0, pos['y'] + 500.0, pos['z'] + 500.0);
      SetGarbageTrucks(0)
      SetRandomBoats(0)
    end
  end)
end

function play_anim_sequence(anim_name, _entity)
  
  while not IsEntityDead(_entity) and DoesEntityExist(_entity) do 
    print('thread running')
    Citizen.Wait(0)
    
    for i = 1, #animations[anim_name] do
      
      local dict = animations[anim_name][i].dict
      local anim = animations[anim_name][i].anim
      
      RequestAnimDict(dict)
      while not HasAnimDictLoaded(dict) do
        Citizen.Wait(1)
      end
      
      TaskPlayAnim(_entity, dict, anim, 2.0, 2.5, -1, 48, 0, 0, 0, 0  )
      Citizen.Wait(200)

      while IsEntityPlayingAnim(_entity, dict, anim, 3) and not IsEntityDead(_entity) do
        Citizen.Wait(1)
      end

    end

  end

  print('leaving thread')
end

function DrawText3D(coords, text, size, font)
	coords = vector3(coords.x, coords.y, coords.z)

	local camCoords = GetGameplayCamCoords()
	local distance = #(coords - camCoords)

	if not size then size = 1 end
	if not font then font = 0 end

	local scale = (size / distance) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	scale = scale * fov

	SetTextScale(0.0 * scale, 0.55 * scale)
	SetTextFont(font)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)

	SetDrawOrigin(coords, 0)
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.0, 0.0)
	ClearDrawOrigin()
end