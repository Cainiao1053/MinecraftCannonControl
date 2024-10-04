local function mat_mult(A, B)
    local M = {{}, {}, {}}
    for i = 1, 3 do for j = 1, 3 do M[i][j] = A[i][1] * B[1][j] + A[i][2] * B[2][j] + A[i][3] * B[3][j] end end
    return M
end

function get_euler(direction)
    local R
    if direction == "east" then
        R = { {0, 0, 1}, {0, 1, 0}, {-1, 0, 0} }
    elseif direction == "west" then
        R = { {0, -1, 0}, {1, 0, 0}, {0, 0, 1} }
    elseif direction == "south" then
        R = { {1, 0, 0}, {0, 1, 0}, {0, 0, 1} }
    elseif direction == "north" then
        R = { {-1, 0, 0}, {0, -1, 0}, {0, 0, -1} }
    else
        error("No direction selected")
    end

    local M = ship.getRotationMatrix()
    M = mat_mult(M, R)

    local yaw, pitch, roll = math.atan2(-M[1][3], M[3][3]), -math.asin(M[2][3]), math.atan2(M[2][1], M[2][2])
    return yaw, pitch, roll
end

function getCannonTable(filename,n) --get Polyfit functions
    local file = io.open(filename);
    local C0raw = {};
    local C0 = {};
    for lines in io.lines(filename) do
        table.insert(C0raw,tonumber(lines));
    end
    file:close();
    for i = 1,5 do
        C0[i] = C0raw[i+5*(n-1)];
    end
    return C0;
end

function getRangeLimit(filename,n) --get range limit
    local file = io.open(filename);
    local limit = {};
    for lines in io.lines(filename) do
        table.insert(limit,tonumber(lines));
    end
    file:close();
    min = limit[2*n - 1];
    max = limit[2*n];
    return min, max;
end

function CannonPoly(C0,C1,diff,w);
    local alpha;
    alpha = C0[1]*w^4+(C0[2]+diff*C1[2]/5)*w^3+(C0[3]+diff*C1[3]/5)*w^2+(C0[4]+diff*C1[4]/5)*w+(C0[5]+diff*C1[5]/5);
    return alpha;
end


function getFlatTarget(posx,posz,posy,xtgt,ztgt,ytgt,C0,C1,minf,maxf,selfVelocity,vxtgt,vztgt) --should run after getting Cs and limits, angles are in deg
    local w = math.sqrt((posx-xtgt)^2+(posz-ztgt)^2);
    local hdiff = ytgt - posy;
    local pitch;
    local yaw = math.atan2(-(xtgt-posx+(vxtgt-selfVelocity.x)*w/(n*40*0.75)),((ztgt-posz+(vztgt-selfVelocity.z)*w/(n*40*0.75))));
    yaw = yaw*180/math.pi
    if yaw<-180 then
        yaw = yaw +360;
    elseif yaw>180 then
        yaw = yaw - 360;
    end
    if w <= minf then
        pitch = w*CannonPoly(C0,C1,0,min)/min+math.atan2(hdiff,w)*180/math.pi;
    elseif w > minf and w < maxf then
        pitch = CannonPoly(C0,C1,hdiff,w);
    elseif w >= maxf then
        pitch = CannonPoly(C0,C1,hdiff,max);
    end
    return pitch,yaw;
end

function getDropTarget(posx,posz,posy,xtgt,ztgt,ytgt,C0d,C1d,C0f,C1f,minf,maxf,mind,maxd,selfVelocity,vxtgt,vztgt)
    local w = math.sqrt((posx-xtgt)^2+(posz-ztgt)^2);
    local hdiff = ytgt - posy;
    local pitch;
    local yaw = math.atan2(-(xtgt-posx+(vxtgt-selfVelocity.x)*w/(n*40*0.45)),((ztgt-posz+(vztgt-selfVelocity.z)*w/(n*40*0.45))));
    yaw = yaw*180/math.pi
    if yaw<-180 then
        yaw = yaw +360;
    elseif yaw>180 then
        yaw = yaw - 360;
    end
    if w <= minf then
        pitch = w*CannonPoly(C0f,C1f,0,minf)/min+math.atan2(hdiff,w)*180/math.pi;
    elseif w >minf and w < mind then
        pitch = CannonPoly(C0f,C1f,hdiff,w)
    elseif w >= mind and w < maxd then
        pitch = CannonPoly(C0d,C1d,hdiff,w);
    elseif w >= maxd then
        pitch = CannonPoly(C0d,C1d,hdiff,maxd);
    end
    return pitch,yaw;
end

function pitchLimit(pitch,uplimit,downlimit)
    if pitch > uplimit then
        pitch = uplimit;
    elseif pitch < downlimit then
        pitch = downlimit;
    end
    return pitch
end

function bearingPD1(ang,angtgt,speedLimit)
    local spd
    local dAng = -(angtgt - ang);
    if dAng >180 then
        dAng = dAng - 360;
    elseif dAng <-180 then
        dAng = dAng + 360;
    end
    spd = ((dAng/15)^3+3*(dAng))
    if spd>speedLimit then
    spd = speedLimit;
    elseif spd<-speedLimit then
    spd = -speedLimit;
    end
    return spd
    end

function bearingPD2(ang,angtgt,speedLimit)
    local spd
    local dAng = -(angtgt - ang);
    if dAng >180 then
        dAng = dAng - 360;
    elseif dAng <-180 then
        dAng = dAng + 360;
    end
    spdfix = ((omegay*math.abs(dAng)));
    if spdfix>3000 then
        spdfix = 3000
    elseif spdfix < -3000 then
        spdfix = -3000
    end
    spd = ((dAng/80)^3+2.5*(dAng))/5 - spdfix/210
    if spd>speedLimit then
    spd = speedLimit;
    elseif spd<-speedLimit then
    spd = -speedLimit;
    end
    return spd
    end

function DrawBackground(w,h)
    term.clear();
    paintutils.drawFilledBox(1,1,w,h,colors.white);
    paintutils.drawFilledBox(1,1,w,1,colors.blue);
    term.setBackgroundColor(colors.blue);
    term.setTextColor(colors.orange);
    local info = "CAInnon"
    term.setCursorPos(w/2-string.len(info)/2,1);
    term.write(info);
    term.setBackgroundColor(colors.white);
    term.setTextColor(colors.black);
end

flatMain = "MainFlatTable.lua";
dropMain = "MainDropTable.lua";
flatErr = "ErrorFlatTable.lua";
dropErr = "ErrorDropTable.lua";
flatRange = "FlatRangeLimitTable.lua";
dropRange = "DropRangeLimitTable.lua";

remoteP = peripheral.wrap("back");
--g = peripheral.wrap("back");
g = {}
guns = remoteP.getNamesRemote()
gunsNum = 0;
for i = 1, #guns do
    if string.find(guns[i],"cbc_cannon_mount") ~=nil then
        gunsNum = gunsNum + 1;
    g[gunsNum] = peripheral.wrap(guns[i]);
    g[gunsNum].assemble();
    end
end
gb1 = peripheral.wrap("right") --pitch
gb2 = peripheral.wrap("left") --yaw
mod = peripheral.wrap("front");
mod.open(386);
rednet.open("front");
commanderID = 3;

posx = -1339; --position of yourself
posy = -59;
posz = -602;
xtgt = 0; --position of target
ytgt = 60;
ztgt = 0;
vxtgt = 0;
vztgt = 0;

tgtshipx0 = 0;
tgtshipz0 = 0;

MODE = "flat";
n = 4;
pi = math.pi;
EXEMODE = 0;
switch = "off";
t0 = 0;
t = 0;
dt = 0;
horfix = 0;
verfix = 0;

C0f = getCannonTable(flatMain,n);
C1f = getCannonTable(flatErr,n);
C0d = getCannonTable(dropMain,n);
C1d = getCannonTable(dropErr,n);
minf, maxf = getRangeLimit(flatRange,n);
mind, maxd = getRangeLimit(dropRange,n);

function Panel()
    while true do
    local w,h = term.getSize()
    DrawBackground(w,h);
    local info = "Status: "..switch;
    term.setCursorPos(w/2-string.len(info)/2,2);
    term.write(info);
    info = "Player Mode"
    term.setCursorPos(w/2-string.len(info)/2,3);
    term.write(info);
    info = "Ship Mode"
    term.setCursorPos(w/2-string.len(info)/2,4);
    term.write(info);
    info = "Location Mode"
    term.setCursorPos(w/2-string.len(info)/2,5);
    term.write(info);
    info = "Firing Mode: "..MODE;
    term.setCursorPos(w/2-string.len(info)/2,6);
    term.write(info);
    local evn,but,cursx,cursy = os.pullEvent("mouse_click");
    if cursy == 2 then
        if EXEMODE ~= 0 then
            EXEMODE = 0;
            switch ="off";
            DrawBackground(w,h)
            info = "System Paused";
            term.setCursorPos(w/2-string.len(info)/2,3);
            term.write(info);
            sleep(0.4);
        else
            DrawBackground(w,h)
            info = "System Already Paused";
            term.setCursorPos(w/2-string.len(info)/2,3);
            term.write(info);
            sleep(0.4);
        end
    elseif cursy == 3 then
        DrawBackground(w,h);
        info = "Enter the target Player";
        term.setCursorPos(w/2-string.len(info)/2,3);
        term.write(info);
        term.setCursorPos(w/2-3,4);
        targetplayer = read();
        EXEMODE = 1;
        info = "Aiming to that shit";
        term.setCursorPos(w/2-string.len(info)/2,5);
        term.write(info);
        switch = "Player"
        sleep(0.3);
    elseif cursy == 4 then
        DrawBackground(w,h);
        info = "Enter the target Vehicle";
        term.setCursorPos(w/2-string.len(info)/2,3);
        term.write(info);
        term.setCursorPos(w/2-3,4);
        targetship = read();
        EXEMODE = 2;
        switch = "Ship";
        info = "Aiming to that shit";
        term.setCursorPos(w/2-string.len(info)/2,5);
        term.write(info);
        sleep(0.3);
    elseif cursy == 5 then
        DrawBackground(w,h);
        info = "Enter the target x axis";
        term.setCursorPos(w/2-string.len(info)/2,3);
        term.write(info);
        term.setCursorPos(w/2-3,4);
        xtgt0 = tonumber(read());
        info = "Enter the target z axis";
        term.setCursorPos(w/2-string.len(info)/2,5);
        term.write(info);
        term.setCursorPos(w/2-3,6);
        ztgt0 = tonumber(read())
        info = "Enter the target y axis";
        term.setCursorPos(w/2-string.len(info)/2,7);
        term.write(info);
        term.setCursorPos(w/2-3,8);
        ytgt0 = tonumber(read());
        if type(xtgt0)=="number" and type(ztgt0)=="number" and type(ytgt0)=="number" then
            xtgt1 = xtgt0;
            ztgt1 = ztgt0;
            ytgt1 = ytgt0;
            EXEMODE = 3;
            switch = "Location"
            info = "Aiming to that shit";
            term.setCursorPos(w/2-string.len(info)/2,9);
            term.write(info);
        else
            info = "Invalid Values";
            term.setCursorPos(w/2-string.len(info)/2,9);
            term.write(info);
        end
    elseif cursy ==6 then
        if MODE == "flat" then
            MODE = "drop"
        elseif MODE == "drop" then
            MODE = "flat";
        else
            MODE = "flat";
        end
        sleep(0.1);
    end
    sleep(0.1);
end
end

function commandReceive()
    while true do
    id, command = rednet.receive(nil,2);
if command ~= nil then
    print(1)
if id == commanderID then
    if command[1] == 1 then
        targetplayer = command[2];
        EXEMODE = command[1];
    elseif command[1] == 2 then
        targetship = command[2];
        EXEMODE = command[1];
    elseif command[1] == 3 then
        xtgt1 = command[2]
        ztgt1 = command[3]
        ytgt1 = command[4]
        EXEMODE = command[1];
    elseif command[1] == 4 then
        if n <=8 then
        MODE = command[2];
        else
            MODE = "flat";
        end
    elseif command[1] == 5 then
        horfix = command[2];
    elseif command[1] == 6 then
        verfix = command[2];
    elseif command[1] == 0 then
        EXEMODE = command[1];
    end
end
end
end
end

function MainThread()
while true do
    if EXEMODE ~=0 then
    t = os.clock();
    dt = t-t0;
    t0 = t;
    worldpos = ship.getWorldspacePosition();
    selfVelocity = ship.getVelocity();
    posx = worldpos.x;
    posz = worldpos.z;
    posy = worldpos.y;
    shipyaw, shippitch, shiproll = get_euler("south");
    shipyaw = shipyaw*180/pi;
    shippitch = shippitch*180/pi;
    shiproll = shiproll*180/pi;
    shipPitchFix = shippitch;
    omega = ship.getOmega();
    omegay = omega.y*180/pi;
    if EXEMODE ==1 then
    players = coord.getEntities(500);
    for key, val in pairs(players) do
        if val.type == "minecraft:player" and val.name == targetplayer then
            xtgt = val.x;
            ytgt = val.y;
            ztgt = val.z;
            vxtgt = 45*val.vector.x;
            vztgt = 45*val.vector.z;
        end
    end
    elseif EXEMODE == 2 then
        ships = coord.getShips(500);
        for key, val in pairs(ships) do
            if val.slug == targetship then
                xtgt = val.x;
                ytgt = val.y;
                ztgt = val.z;
                vxtgt = (xtgt-tgtshipx0)/dt
                vztgt = (ztgt-tgtshipz0)/dt
                tgtshipx0 = xtgt;
                tgtshipz0 = ztgt;
            end
        end
    elseif EXEMODE == 3 then
        xtgt = xtgt1;
        ytgt = ytgt1;
        ztgt = ztgt1;
    end
if MODE == "flat" then
    pitchAngle,yawAngle = getFlatTarget(posx,posz,posy,xtgt,ztgt,ytgt,C0f,C1f,minf,maxf,selfVelocity,vxtgt,vztgt);
elseif MODE == "drop" then
    pitchAngle, yawAngle = getDropTarget(posx,posz,posy,xtgt,ztgt,ytgt,C0d,C1d,C0f,C1f,minf,maxf,mind,maxd,selfVelocity,vxtgt,vztgt)
end
if yawAngle<-180 then --limit for bearing itself
    yawAngle = yawAngle+360;
elseif yawAngle>180 then
    yawAngle = yawAngle-360
end
pitchAngle = pitchAngle+shipPitchFix+verfix;
pitchAngle = pitchLimit(pitchAngle,60,-10);
yawAngle = yawAngle + horfix;
--g.setPitch(pitchAngle);
speedPitch = bearingPD1(g[1].getPitch(),pitchAngle,128);
speedYaw = bearingPD2(shipyaw, yawAngle, 128);
--g.setYaw(yawAngle);
gb1.setTargetSpeed(speedPitch);
gb2.setTargetSpeed(speedYaw);
else
    sleep(1);
end
sleep(0.05)
end
end

parallel.waitForAny(MainThread,commandReceive)