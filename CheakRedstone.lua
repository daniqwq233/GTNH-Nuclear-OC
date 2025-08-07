local redstone = component.proxy(component.list("redstone")())
local transposer = component.proxy(component.list("transposer")())

local sides = {bottom = 0, top = 1, back = 2, front = 3, right = 4, left = 5}
local reactorCoolantCellIndex = {3, 6, 9, 10, 15, 22, 26, 29, 33, 40, 45, 46, 49, 52}
local reactorFuelRodsIndex = {
    1, 2, 4, 5, 7, 8, 11, 
    12, 13, 14, 16, 17, 18, 
    19, 20, 21, 23, 24, 25, 
    27, 28, 30, 31, 32, 34, 
    35, 36, 37, 38, 39, 41, 
    42, 43, 44, 47, 48, 50, 
    51, 53, 54
}

local reactor = sides.bottom
local me_interface = sides.top
local me_interfaceCoolantCellIndex = 2
local me_interfaceFuelRodsIndex = 1
local me_interfaceEmptyIndex = 9

local function sleep(interval)
    computer.pullSignal(interval)
end

local function waitRedstoneOff(timeout)
    local t = 0
    while redstone.getOutput(reactor) > 0 do
        sleep(0.1)
        t = t + 0.1
        if timeout and t > timeout then
            break
        end
    end
end

local function shutdown()
    redstone.setOutput(reactor, 0)
    waitRedstoneOff(3)
    computer.shutdown(true)
end

local function pause()
    redstone.setOutput(reactor, 0)
    waitRedstoneOff(3)
end

local function checkHasCoolantCell()
    if transposer.getStackInSlot(me_interface, me_interfaceCoolantCellIndex) == nil then
        shutdown()
    end
end

local function checkHasFuelRods()
    if transposer.getStackInSlot(me_interface, me_interfaceFuelRodsIndex) == nil then
        shutdown()
    end
end

local function check()
    local reactorItems = transposer.getAllStacks(reactor).getAll()
    checkHasCoolantCell() 
    checkHasFuelRods() 

    local flag = 0
    for _, i in pairs(reactorCoolantCellIndex) do 
        local item = reactorItems[i - 1]
        if next(item) == nil then
            pause()
            if flag == 0 then
                flag = 1
                sleep(1)
            end
            checkHasCoolantCell()
            transposer.transferItem(me_interface, reactor, 1, me_interfaceCoolantCellIndex, i)
            reactorItems = transposer.getAllStacks(reactor).getAll() 
        else
            if item['damage'] > 85 then
                pause()
                if flag == 0 then
                    flag = 1
                    sleep(1)
                end
                checkHasCoolantCell()
                transposer.transferItem(reactor, me_interface, 1, i, me_interfaceEmptyIndex)
                transposer.transferItem(me_interface, reactor, 1, me_interfaceCoolantCellIndex, i)
                reactorItems = transposer.getAllStacks(reactor).getAll() 
            end
        end
    end

    if redstone.getInput(sides.back) > 0 then 
        shutdown()
    end

    for _, i 在 pairs(reactorFuelRodsIndex) do 
        local item = reactorItems[i - 1]
        if next(item) == nil then
            checkHasFuelRods()
            transposer.transferItem(me_interface, reactor, 1, me_interfaceFuelRodsIndex, i)
            reactorItems = transposer.getAllStacks(reactor).getAll()
        else
            if item['maxDamage'] == 0 then
                checkHasFuelRods()
                transposer.transferItem(reactor, me_interface, 1, i, me_interfaceEmptyIndex)
                transposer.transferItem(me_interface, reactor, 1, me_interfaceFuelRodsIndex, i)
                reactorItems = transposer.getAllStacks(reactor).getAll()
            end
        end
    end

    local newItems = transposer.getAllStacks(reactor).getAll()
    for _, k in pairs(newItems) do
        if next(k) == nil then
            computer.shutdown(true)
        end
    end

    redstone.setOutput(reactor, 15) 
end

local function main()
    check()
    computer.shutdown(true)
end

main()
