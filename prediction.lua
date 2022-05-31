local Prediction = {}

local function IsZero(d) 
    local eps = 0.000001
    return d > -eps and d < eps
end

local function GetCubicRoot(value)

    if (value > 0) then
        return math.pow(value, 1/3)
    elseif (value < 0) then
        return -math.pow(-value, 1/3)
    end
    return 0
end

local function SolveQuadric(c0, c1, c2)
    local s0 = 0
    local s1 = 0
    local p,q,D

    p = c1 / (2 * c0)
    q = c2 / c0

    D = p * p - q

    if (IsZero(D)) then
        s0 = -p
        return 1, s0, s1
    elseif (D < 0) then
        return 0, s0, s1
    end
    sqrt_D = math.sqrt(D)
    s0 = sqrt_D - p
    s1 = -sqrt_D - p
    return 2, s0, s1
end

local function SolveCubic(c0, c1, c2, c3)
    local s0,s1,s2 = 0,0,0
    local num,sub,A,B,C,sq_A,p,q,cb_p,D = 0,0,0,0,0,0,0,0,0,0
    A = c1/c0
    B = c2/c0
    C = c3/c0

    sq_A = A * A
    p = 1.0/3 * (-1.0/3 * sq_A + B)
    q = 1.0/2 * (2.0/27 * A * sq_A - 1.0/3 * A * B + C)

    cb_p = math.pow(p, 3)
    D = q * q + cb_p

    if (IsZero(D)) then
        if (IsZero(q)) then
            s0 = 0
            num = 1
        else
            local u = GetCubicRoot(-q)
            s0 = 2 * u
            s1 = -u
            num = 2
        end
    elseif (D < 0) then
        local phi = 1.0/3 * math.acos(-q / math.sqrt(-cb_p))
        local t = 2 * math.sqrt(-p)

        s0 = t * math.cos(phi)
        s1 = -t * math.cos(phi + math.pi / 3)
        s2 = -t * math.cos(phi - math.pi / 3)
        num = 3
    else
        local sqrt_D = math.sqrt(D)
        local u = GetCubicRoot(sqrt_D - q)
        local v = -GetCubicRoot(sqrt_D + q)
        s0 = u + v
        num = 1
    end
    sub = 1.0/3 * A
    if (num > 0) then
        s0 = s0 - sub
    end
    if (num > 1) then
        s1 = s1 - sub
    end
    if (num > 3) then
        s2 = s2 - sub
    end

    return num,s0,s1,s2
end

local function SolveQuartic(c0, c1, c2, c3, c4)
    local s0,s1,s2,s3 = 0,0,0,0
    local coeffs = {0,0,0,0}
    local z, u, v, sub
    local A, B, C, D
    local sq_A, p, q, r
    local num

    A = c1 / c0
    B = c2 / c0
    C = c3 / c0
    D = c4 / c0

    sq_A = A * A
    p = - 3.0/8 * sq_A + B
    q = 1.0/8 * sq_A * A - 1.0/2 * A * B + C
    r = -3.0/256*sq_A*sq_A + 1.0/16*sq_A*B - 1.0/4*A*C + D

    if(IsZero(r)) then
        coeffs[4] = q
        coeffs[3] = p
        coeffs[2] = 0
        coeffs[1] = 1

        num,s0,s1,s2 = SolveCubic(coeffs[1],coeffs[2],coeffs[3],coeffs[4])
    else
        coeffs[4] = 1/2 * r * p - 1/8 * q * q
        coeffs[3] = -r
        coeffs[2] = -1/2 * p
        coeffs[1] = 1

        e,s0,s1,s2 = SolveCubic(coeffs[1],coeffs[2],coeffs[3],coeffs[4])

        z = s0
        u = z * z - r
        v = 2 * z - p
        if (IsZero(u)) then
            u = 0
        elseif (u > 0) then
            u = math.sqrt(u)
        else
            return 0
        end
        if (IsZero(v)) then
            v = 0
        elseif (v > 0) then
            v = math.sqrt(v)
        else
            return 0
        end

        coeffs[3] = z - u
        if (q < 0) then
            coeffs[2] = -v
        else
            coeffs[2] = v
        end
        coeffs[0] = 1
        num,s0,s1 = SolveQuadric(coeffs[1],coeffs[2],coeffs[3])
        
        coeffs[3] = z + u
        coeffs[2] = - coeffs[2]
        coeffs[1] = 1
        if (num == 0) then
            local temp
            temp,s0,s1 = SolveQuadric(coeffs[1],coeffs[2],coeffs[3])
            num = num + temp
        elseif (num == 1) then
            local temp
            temp,s1,s2 = SolveQuadric(coeffs[1],coeffs[2],coeffs[3])
            num = num + temp
        elseif (num == 2) then
            local temp
            temp,s2,s3 = SolveQuadric(coeffs[1],coeffs[2],coeffs[3])
            num = num + temp
        end
    end

    sub = 1/4 * A
    if (num > 0) then
        s0 = s0 - sub
    end
    if (num > 1) then
        s1 = s1 - sub
    end
    if (num > 2) then
        s2 = s2 - sub
    end
    if (num > 3) then
        s3 = s3 - sub
    end

    return num,s0,s1,s2,s3
end

local function ballistic_range(speed, gravity, initial_height)
    local angle = math.rad(45)
    local cos = math.cos(angle)
    local sin = math.sin(angle)

    local range = (speed*cos/gravity) * (speed*sin + math.sqrt(speed*speed*sin*sin + 2*gravity*initial_height))
    return range
end
Prediction.ballistic_range = ballistic_range

local function solve_ballistic_arc(ignore, proj_pos, proj_speed, target_pos, target_velocity, gravity)
	local temp = proj_pos
	target_pos = target_pos - proj_pos
	proj_pos = Vector3.new(0,0,0)
    local s0,s1 = Vector3.new(0,0,0), Vector3.new(0,0,0)
    local G = gravity
    local A = proj_pos.X
    local B = proj_pos.Y
    local C = proj_pos.Z
    local M = target_pos.X
    local N = target_pos.Y
    local O = target_pos.Z
    local P = target_velocity.X
    local Q = target_velocity.Y
    local R = target_velocity.Z
    local S = proj_speed
    local H = M - A
    local J = O - C
    local K = N - B
    local L = -0.5 * G
    local c0 = L * L
    local c1 = -2 * Q * L
    local c2 = Q * Q - 2 * K * L - S * S + P * P + R * R
    local c3 = 2 * K * Q + 2 * H * P + 2 * J * R
    local c4 = K * K +  H * H + J * J
    local times = {0,0,0,0}
    local numTimes
    numTimes, times[1], times[2], times[3], times[4] = SolveQuartic(c0, c1, c2, c3, c4)
    table.sort(times)
    local solutions = {Vector3.new(0,0,0), Vector3.new(0,0,0)}
    local numSolutions = 0
    local i = 1
    while(i <= #times and numSolutions < 2) do
        local t = times[i]
        if (t <= 0 or t ~= t) then
        else
            solutions[numSolutions] = Vector3.new((H+P*t)/t,(K + Q *t - L * t * t)/t,(J + R * t)/t)
            numSolutions = numSolutions + 1
        end
        i = i + 1
    end
    if (numSolutions > 0) then
        s0 = solutions[0]
    end
    if (numSolutions > 1) then
        s1 = solutions[1]
    end
    return numSolutions, s0 + temp, s1 + temp
end
Prediction.solve_ballistic_arc = solve_ballistic_arc
return Prediction