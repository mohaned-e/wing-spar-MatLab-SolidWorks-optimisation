

function [yu, yl] = local_aerofoil_height(x_frac, T, M, P, chord_mm)
    yt = 5*T*(0.2969*sqrt(x_frac) - 0.126*x_frac - 0.3516*x_frac^2 + 0.2843*x_frac^3 - 0.1015*x_frac^4);  
    
    if x_frac < P              
        yc  = (M/P^2) * (2*P*x_frac - x_frac^2);
    else
        yc = (M/(1-P)^2) * ((1-2*P) + 2*P*x_frac - x_frac^2);  
    end
     
    if x_frac < P
        dyc_dx  = (2*M/P^2) * (P - x_frac);  
    else
        dyc_dx = (2*M/(1-P)^2) * (P - x_frac);  
    end
    theta = atan(dyc_dx);

    yu = (yc + yt.*cos(theta)) * chord_mm;
    yl = (yc - yt.*cos(theta)) * chord_mm;
end

