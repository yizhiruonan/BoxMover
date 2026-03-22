local Script = {}
local 储物箱 = {
    [1180]={[4]=true,[5]=true,[6]=true,[7]=true},
    [1181]={[0]=true,[1]=true,[2]=true,[3]=true},
    [390103]={[4]=true,[5]=true,[6]=true,[7]=true},
    [390105]={[0]=true,[1]=true,[2]=true,[3]=true},
    [390008]={[0]=true,[1]=true,[2]=true,[3]=true}
}
local 映射表 = {
    [1180] = true, [1181] = true, [390103] = true, [390105] = true,
    [390008] = true, [150022] = true, [200379] = true, [201502] = true,
    [969] = true, [974] = true, [979] = true, [1815] = true, [734] = true
}
local kvid = "v761707541772642165262660"

function Script:获取面向玩家的data(yaw, blockId)
    if not 映射表[blockId] then
        return 0
    end
    
    yaw = yaw % 360
    
    if yaw >= 225 and yaw < 315 then--东
        return 0
    elseif (yaw >= 0 and yaw < 45) or (yaw >= 315 and yaw < 360) then--南
        return 3
    elseif yaw >= 45 and yaw < 135 then--西
        return 1
    elseif yaw >= 135 and yaw < 225 then--北
        return 2
    end
    
    return 0
end

-- 组件启动时调用
function Script:OnStart()
    self.V = self.V or {}
    self:AddTriggerEvent(TriggerEvent.GameAnyPlayerEnterGame, self.进入游戏)
    self:AddTriggerEvent(TriggerEvent.PlayerClickBlock, self.点击方块)
    self:AddTriggerEvent(TriggerEvent.PlayerInputKeyDown, self.按下按键)
    self:AddTriggerEvent(TriggerEvent.PlayerInputKeyUp, self.抬起按键)
    self:AddTriggerEvent(TriggerEvent.PlayerInputKeyClick, self.点击按键)
end

function Script:进入游戏(e)
    local uin = e.eventobjid
    self.V[uin] = self.V[uin] or {}
end

function Script:按下按键(e)
    local uin, key = e.eventobjid, e.vkey
    if Player:GetClientInfo(uin) ~= 1 then
        return
    end
    if key ~= KeyCode.Shift or self.V[uin] == nil then
        return
    end
    self.V[uin]["潜行状态"] = true
end

function Script:抬起按键(e)
    local uin, key = e.eventobjid, e.vkey
    if Player:GetClientInfo(uin) ~= 1 then
        return
    end
    if key ~= KeyCode.Shift or self.V[uin] == nil then
        return
    end
    self.V[uin]["潜行状态"] = false
end

function Script:点击按键(e)
    local uin, key = e.eventobjid, e.vkey
    if Player:GetClientInfo(uin) == 1 then
        return
    end
    if key ~= KeyCode.Shift or self.V[uin] == nil then
        return
    end
    self.V[uin]["潜行状态"] = not(self.V[uin]["潜行状态"] or false)
end

function Script:搬箱子(uin, x, y, z, id, index)
    
    Backpack:SetBackPackNum(uin, 100)
    Backpack:ClearGrids(uin, BackpackBeginIndex.Inventory + 30, BackpackBeginIndex.Inventory + 99)

    local data, num = {}, 0
    for i = 1, 100 do
        local itemId, Num = WorldContainer:GetStorageItem(x, y, z, i, WorldId)
        if itemId and itemId ~= 0 and Num ~= 0 then
            WorldContainer:SwapContainerItem(x, y, z, i, uin, BackpackBeginIndex.Inventory + 29 + i)
            num = num + 1
        end
    end
    data = Backpack:GetGridInfos(uin,BackpackBeginIndex.Inventory + 30,BackpackBeginIndex.Inventory + 99)
    Backpack:SetBackPackNum(uin, 30)
    Block:DestroyBlock(x, y, z, false, WorldId)
    local sid = Backpack:CreateItemInstInBackpack(uin, "r2_7616995810507590292_62656", index)
    Item:ReplaceSubModelPart(sid, "guazai", "", Item:GetFacade(id), {x=0, y=0.49, z=-0.03}, {x = 0, y = 0, z = 0}, {x=1.07, y=1.07, z=1.07})

    Data.Map:SetValueAndBlock(kvid, nil, sid, json.encode({data=data, id=id, num=num}))
end

function Script:获取放置位置(uin, l)
    local x, y, z = Actor:GetPosition(uin)
    y = y + 1.5
    local pitch = math.rad(Actor:GetFacePitch(uin))
    local yaw = math.rad(Actor:GetFaceYaw(uin))
    local cos_p, sin_p = math.cos(pitch), math.sin(pitch)
    local cos_y, sin_y = math.cos(yaw), math.sin(yaw)
    local vx = -cos_p * sin_y
    local vy = -sin_p
    local vz = -cos_p * cos_y
    
    local t = 0
    local ax, ay, az = 1.0/vx, 1.0/vy, 1.0/vz
    local ex, ey, ez = ax < 0 and -ax or ax, ay < 0 and -ay or ay, az < 0 and -az or az
    local tx = 0.5 * (ex + ax) - (x % 1) * ax
    local ty = 0.5 * (ey + ay) - (y % 1) * ay
    local tz = 0.5 * (ez + az) - (z % 1) * az
    tx = tx == tx and tx or math.huge
    ty = ty == ty and ty or math.huge
    tz = tz == tz and tz or math.huge
    local px, py, pz = 0, 0, 0
    while t < l do
        local checkX = math.floor(x + t*vx + 0.5*px)
        local checkY = math.floor(y + t*vy + 0.5*py)
        local checkZ = math.floor(z + t*vz + 0.5*pz)

        if Block:IsAirBlock(checkX, checkY, checkZ, WorldId) then
            return true, {x = x + t*vx,y = y + t*vy,z = z + t*vz}
        end

        if tx < ty and tx < tz then
            t = tx
            tx = tx + ex
            px = vx >= 0 and 1 or -1
            py, pz = 0, 0
        elseif ty < tz then
            t = ty
            ty = ty + ey
            py = vy >= 0 and 1 or -1
            px, pz = 0, 0
        else
            t = tz
            tz = tz + ez
            pz = vz >= 0 and 1 or -1
            px, py = 0, 0
        end
    end
    return false, {x = x + vx * l,y = y + vy * l,z = z + vz * l}
end

function Script:放箱子(uin, sid, value, index)
    local 数据 = json.decode(value)
    local 结果, 位置 = self:获取放置位置(uin, Actor:GetAttr(uin, CreatureAttr.AttackDis))
    if not 结果 then
        return
    end
    if Backpack:GetInstIdByGridIndex(uin, index) ~= sid then
        return
    end
    local result = Backpack:ClearGrids(uin, index, index)
    if not result then
        return
    end
    Block:SetBlockAll(位置.x, 位置.y, 位置.z, 数据.id, self:获取面向玩家的data(Actor:GetFaceYaw(uin), 数据.id), worldId)
    Data.Map:RemoveValueAndBlock(kvid, nil, sid)

    Backpack:SetBackPackNum(uin, 100)
    Backpack:ClearGrids(uin, BackpackBeginIndex.Inventory + 30, BackpackBeginIndex.Inventory + 99)
    Backpack:LoadGridInfos(uin, 数据.data)
    for k = 1, 数据.num do
        WorldContainer:SwapContainerItem(位置.x, 位置.y, 位置.z, k, uin, BackpackBeginIndex.Inventory + 29 + k)
    end
     Backpack:SetBackPackNum(uin, 30)
end


function Script:点击方块(e)
    local x, y, z, id, uin = e.x, e.y, e.z, e.blockid, e.eventobjid
    local 选中index = BackpackBeginIndex.Shortcut + Player:GetShotcutIndex(uin) - 1
    local instId = Backpack:GetInstIdByGridIndex(uin, 选中index)
    local code, key, value = Data.Map:GetValueAndBlock(kvid, nil, instId)

    if code == ErrorCode.OK then
        --放
        self:放箱子(uin, instId, value, 选中index)
    else
        --搬
        if not WorldContainer:CheckStorage(x, y, z, WorldId) then
            return
        end

        if not self.V[uin] then
            Chat:SendSystemMsg("数据无效")
            return
        end

        if not self.V[uin]["潜行状态"] then
            return
        end

        local 选中格子数据 = (Backpack:DecodeGridInfo(Backpack:GetGridInfos(uin, 选中index, 选中index)))[1]
        if 选中格子数据["itemid"] then
            Chat:SendSystemMsg("请空手进行搬箱子行为")
            return
        end

        local 方块data = Block:GetBlockData(x, y, z, WorldId)
        if 储物箱[id] and 储物箱[id][方块data] then
            return
        end

        self:搬箱子(uin, x, y, z, id, 选中index)
    end
end

return Scriptfunction Script:OnStart()
    self.V = self.V or {}
    self:AddTriggerEvent(TriggerEvent.GameAnyPlayerEnterGame, self.进入游戏)
    self:AddTriggerEvent(TriggerEvent.PlayerClickBlock, self.点击方块)
    self:AddTriggerEvent(TriggerEvent.PlayerInputKeyDown, self.按下按键)
    self:AddTriggerEvent(TriggerEvent.PlayerInputKeyUp, self.抬起按键)
end

function Script:进入游戏(e)
    local uin = e.eventobjid
    self.V[uin] = self.V[uin] or {}
end

function Script:按下按键(e)
    local uin, key = e.eventobjid, e.vkey
    if key ~= KeyCode.Shift or self.V[uin] == nil then
        return
    end
    self.V[uin]["潜行状态"] = true
end

function Script:抬起按键(e)
    local uin, key = e.eventobjid, e.vkey
    if key ~= KeyCode.Shift or self.V[uin] == nil then
        return
    end
    self.V[uin]["潜行状态"] = false
end

function Script:搬箱子(uin, x, y, z, id, index)
    
    Backpack:SetBackPackNum(uin, 100)
    Backpack:ClearGrids(uin, BackpackBeginIndex.Inventory + 30, BackpackBeginIndex.Inventory + 99)

    local data, num = {}, 0
    for i = 1, 100 do
        local itemId, Num = WorldContainer:GetStorageItem(x, y, z, i, WorldId)
        if itemId and itemId ~= 0 and Num ~= 0 then
            WorldContainer:SwapContainerItem(x, y, z, i, uin, BackpackBeginIndex.Inventory + 29 + i)
            num = num + 1
        end
    end
    data = Backpack:GetGridInfos(uin,BackpackBeginIndex.Inventory + 30,BackpackBeginIndex.Inventory + 99)
    Backpack:SetBackPackNum(uin, 30)
    Block:DestroyBlock(x, y, z, false, WorldId)
    local sid = Backpack:CreateItemInstInBackpack(uin, "r2_7616995810507590292_62656", index)
    Item:ReplaceSubModelPart(sid, "guazai", "", Item:GetFacade(id), {x=0, y=0.49, z=-0.03}, {x = 0, y = 0, z = 0}, {x=1.07, y=1.07, z=1.07})

    Data.Map:SetValueAndBlock(kvid, nil, sid, json.encode({data=data, id=id, num=num}))
end


function Script:获取放置位置(uin, l)
    local x, y, z = Actor:GetPosition(uin)
    y = y + 1.5
    local pitch, yaw = math.rad(Actor:GetFacePitch(uin)), math.rad(Actor:GetFaceYaw(uin))
    local cos_p, sin_p = math.cos(pitch), math.sin(pitch)
    local cos_y, sin_y = math.cos(yaw), math.sin(yaw)
    local 向量 = {
        x = -cos_p * sin_y,
        y = -sin_p,
        z = -cos_p * cos_y
    }
    local d = World:GetRayLength(x, y, z, x+向量.x*l, y+向量.y*l, z+向量.z*l, 1)
    local len = math.min(l, d and d or l)

    if len <= -1 then
        return false, nil
    end

    local 位置 = d and {x =x + 向量.x*len, y = y + 向量.y*len, z = z + 向量.z * len} or {x=x, y=y, z=z}
    
    local kx, ky, kz = (位置.x - x)/len, (位置.y - y)/len, (位置.z - z)/len
    local _x, _y, _z, 成功 = 0, 0, 0, false
    for i = len, 0, -0.5 do
        _x, _y, _z = math.floor(x + i*kx), math.floor(y + i*ky), math.floor(z + i*kz)
        if Block:IsSolidBlock(_x, _y, _z, WorldId) == false then
            成功 = true
            break
        end
    end
    if 成功 then
        return true, {x=_x, y=_y, z=_z}
    else
        return false, nil
    end
end

function Script:放箱子(uin, sid, value, index)
    local 数据 = json.decode(value)
    local 结果, 位置 = self:获取放置位置(uin, 8)
    if not 结果 then
        return
    end
    if Backpack:GetInstIdByGridIndex(uin, index) ~= sid then
        return
    end
    local result = Backpack:ClearGrids(uin, index, index)
    if not result then
        return
    end
    Block:SetBlockAll(位置.x, 位置.y, 位置.z, 数据.id, self:获取面向玩家的data(Actor:GetFaceYaw(uin), 数据.id), worldId)
    Data.Map:RemoveValueAndBlock(kvid, nil, sid)

    Backpack:SetBackPackNum(uin, 100)
    Backpack:ClearGrids(uin, BackpackBeginIndex.Inventory + 30, BackpackBeginIndex.Inventory + 99)
    Backpack:LoadGridInfos(uin, 数据.data)
    for k = 1, 数据.num do
        WorldContainer:SwapContainerItem(位置.x, 位置.y, 位置.z, k, uin, BackpackBeginIndex.Inventory + 29 + k)
    end
     Backpack:SetBackPackNum(uin, 30)
end


function Script:点击方块(e)
    local x, y, z, id, uin = e.x, e.y, e.z, e.blockid, e.eventobjid
    local 选中index = BackpackBeginIndex.Shortcut + Player:GetShotcutIndex(uin) - 1
    local instId = Backpack:GetInstIdByGridIndex(uin, 选中index)
    local code, key, value = Data.Map:GetValueAndBlock(kvid, nil, instId)

    if code == ErrorCode.OK then
        --放
        self:放箱子(uin, instId, value, 选中index)
    else
        --搬
        if not WorldContainer:CheckStorage(x, y, z, WorldId) then
            return
        end

        if not self.V[uin] then
            Chat:SendSystemMsg("数据无效")
            return
        end

        if not self.V[uin]["潜行状态"] then
            return
        end

        local 选中格子数据 = (Backpack:DecodeGridInfo(Backpack:GetGridInfos(uin, 选中index, 选中index)))[1]
        if 选中格子数据["itemid"] then
            Chat:SendSystemMsg("请空手进行搬箱子行为")
            return
        end

        local 方块data = Block:GetBlockData(x, y, z, WorldId)
        if 储物箱[id] and 储物箱[id][方块data] then
            return
        end

        self:搬箱子(uin, x, y, z, id, 选中index)
    end
end

return Script
