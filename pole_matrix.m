function [ A ] = pole_matrix( p, N )
%Vandermonde matrix on the poles
%performs task of finding impulse responses components to horizon

%p: set of poles in complex plane (must include conjugates)
%N: horizon, number of samples
k = length(p);

%response of 1/(z-p) = r^n (cos(n theta) + j sin(n theta))
r = abs(p);
theta = angle(p);

scale = (1 - r.^2)./2;
  
%raise r to powers
index_N = ones(1,N-2);
mag = cumprod(r(index_N, :));

angles = (1:N-2)'*theta; %n*theta

%optional step
angles = mod(angles, 2*pi);

%poles with a+bi will have cos, a-bi will have sin
%exponentials are normal, with cos(0) = 1
angles(:, theta < 0) = angles(:, theta < 0) + pi/2;

vandermonde = mag .* cos(angles);
vandermonde_scaled = vandermonde * diag(scale);

A = [zeros(1,k);ones(1,k); vandermonde_scaled];


end
