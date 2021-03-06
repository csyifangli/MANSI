%% Atomic Norm sysid testing

%p_sys = [0.3+0.5j, 0.3-0.5j, 0.8];
%p_sys = [0.9*exp(2.5j), 0.9*exp(-2.5j)];
%p_sys = [0.8*exp(0.1j), 0.8*exp(-0.1j)];
%p_sys = [-0.9; 0.5];
%p_sys = [0; 0.9];
%p_sys = [0.65];
%p_sys = [1/sqrt(2)];
%p_sys = [-0.005 + 0.5j; -0.005 - 0.5j];
%p_sys = [0.95j; -0.95j];
%p_sys = [0.7j; -0.7j; 0.2];
%p_sys = [-0.5 + 0.5j, -0.5 - 0.5j];
%p_sys = [-1];
%p_sys = [0.75; 0.95];
p_sys = [0.4; 0.9];
%p_sys = [0.3; 0.5];
%p_sys = [0.3; 0.7];
%p_sys = [0.8];
%p_sys = [-0.5 + 0.5j, -0.5 - 0.5j, 0.7];

%b = [1];
b = [1 -0.5];
%b = [1 0.8];
%b = [length(p_sys) sum(p_sys)]
%b = [1 0.5];
%b = [1 0];
a = poly(p_sys);
Fs = 1;
sysd = tf(b, a, Fs);
[r_true, ~, ~] = residue(b, a);
c_true = r_true;
%deal with complex poles/complex residues
%as per convention, imag(p)>0: cos, imag(p)<0: sin, imag(p)=0: exp
c_true(imag(c_true) > 0) = 2*real(c_true(imag(c_true) > 0));
c_true(imag(c_true) < 0) = 2*imag(c_true(imag(c_true) < 0));

In.visualize = 0;
In.visualize_end = 1;

%In.tau.tauAtom = 1.65;
%In.tau.tauAtom = 5;
%In.tau.tauAtom = 1.24;
In.tau.tauAtom = 7.5;
%In.tau.tauAtom = 1.3;


In.tau.delta = 1e-4; %Elastic Net Regularization
%In.tau.delta = 0; %Elastic Net Regularization

%In.tau.lambda = 1e-1;
%In.tau.lambda = 1e-2;

In.t_max = 1000;
In.k = 150;

N = 101;
response_type = 0;
if response_type == 1
    %step response
    %no idea how this will go
    
    %the scaling for this is screwed up. massively.
    %and the closed-form formulas are horrific
    In.T = tril(ones(N));
    y = step(sysd, 0:N-1);
else
    %impulse response
    In.T = eye(N);
    y = impulse(sysd, 0:N-1);
end
In.ym = y;

%% define location of poles to be tested
%radius = 5;
%radius = 10;
radius = 20;
%radius = 40;
%radius = 200;
Npoles = 2*radius + 1;
rho = 1;

%poles on unit circle will ring forever, are excluded.
[poles_xx, poles_yy] = meshgrid(linspace(-rho, rho, Npoles));
poles = poles_xx + 1.0j*poles_yy;
poles_circ = poles(abs(poles) <= 1);
poles_circ = reshape(poles_circ, [1, length(poles_circ)]);

%real line only
%poles_circ = linspace(-rho, rho, Npoles);

%clear up numerical artifacts
poles_circ(abs(imag(poles_circ)) < 1e-10) = real(poles_circ(abs(imag(poles_circ)) < 1e-10));
poles_circ(abs(real(poles_circ)) < 1e-10) = 1.0j * imag(poles_circ(abs(real(poles_circ)) < 1e-10));

In.p_in = poles_circ;
%In.p_in = poles_circ';
In.k = length(poles_circ);

%% Run sysid system

%Out = atomic_SISO(In);
%Out = ANSI_forward(In);
Out = ANSI_away(In);
%Out = ANSI_pair(In);
%Out = ADMMSI(In);
y_hat = Out.h;

%% recovering transfer function
%in real formulation, poles responses are cosines and sines
%this means that a pure cosine response will have the upper half pole
%but not the corresponding conjugate lower half pole. Use this to find
%all poles, the true order of the system, and the final transfer function.
c = Out.c;
active_ind = find(c ~= 0);
poles_active = poles_circ(active_ind);

ca = c(active_ind);
ca(abs(ca) < 1e-15) = 0; %relative tolerance

%find full set of poles in system
%if there is a complex pole, make sure its conjugate is included
%there is an issue here with the indexing, where union doesn't get
%me what I expect. I want 
pa = poles_active;
% pc = conj(pa);
% 
% [pu, ip, ipc] = union(pa, pc);
% 
% order = length(pu);
% cu = zeros(size(pu));
% 
% %find where values in p are in the union
% %this is hackery
% [~, ipsort] = sort(pa);
% 
% p_locations = find(ismember(pu, pa));
% cu(p_locations) = ca(ipsort);
% 
% %fill in values of the residues
% r = zeros(size(pu));
% r(imag(pu) == 0) = cu(imag(pu) == 0);
% 
% ind_real = find(imag(pu) == 0);
% ind_trig = find(imag(pu) ~= 0);
% ind_cos = ind_trig(1:2:length(ind_trig));
% ind_sin = ind_trig(2:2:length(ind_trig));
% 
% residue_top    = (cu(ind_cos) + 1.0j*cu(ind_sin))/2;
% residue_bottom = (cu(ind_cos) - 1.0j*cu(ind_sin))/2;
% 
% r(ind_cos) = residue_top;
% r(ind_sin) = residue_bottom;

%transfer function testing
% [bp, ap] = residue(r, pu, 0);
% bp = real(bp);
% sysp = tf(bp, ap, Fs);

%more numerically stable way to get zeros
% [z, k] = zeros_from_poles(r, pu);
% 
% sysp = zpk(z, pu, k, Fs);

%% try manually combining the poles together
% sys_accum = 0;
% %real poles
% for i = ind_real
%     sys_curr = zpk([], pu(i), r(i), Fs);
%     sys_accum = sys_accum + sys_curr;
% end
% 
% %complex poles
% for i = ind_cos
%     rc = r(i);
%     pcurr = pu(i);
%     k = rc + conj(rc);
%     s = (rc*conj(pcurr) + conj(rc)*pcurr);
%     
%     %k = 0, pure cos
%     %k = Inf, pure sin
%     %k = else, mix
%     %need to validate
%     
%     if k == 0
%         sys_curr = zpk([], [pcurr, conj(pcurr)], -s, Fs);
%     else
%         sys_curr = zpk(s/k, [pcurr, conj(pcurr)], k, Fs);
%     end
% 
%     sys_accum = sys_accum + sys_curr;
% end
% 
% sysp = sys_accum;

%reduced model of sysp
spacing_tol = (1/radius)/2;
% sysr = minreal(sysp, spacing/2);

[sysp, sysr] = zpk_from_poles(ca, pa, spacing_tol, Fs);

sysd_zero = zero(sysd);
sysd_pole = pole(sysd);

sysp_zero = zero(sysp);
sysp_pole = pole(sysp);

sysr_zero = zero(sysr);
sysr_pole = pole(sysr);

figure
hold on
sd = scatter(real(sysd_zero), imag(sysd_zero), 150, 'bo');
scatter(real(sysd_pole), imag(sysd_pole), 150, 'bx')

sr = scatter(real(sysr_zero), imag(sysr_zero), 70, 'ko');
scatter(real(sysr_pole), imag(sysr_pole), 70, 'kx')

sp = scatter(real(sysp_zero), imag(sysp_zero), 20, 'ro');
scatter(real(sysp_pole), imag(sysp_pole), 20, 'rx')

legend([sd, sr, sp], 'ground truth', 'reduced fitted model', 'fitted model')
legend('boxoff')

th = linspace(0, 2*pi, 400);
plot(cos(th), sin(th), 'color', [0 .5 0] )

hold off
axis square
xlabel('Re(z)')
ylabel('Im(z)')
title('system pole zero map')

%% Plotting impulse responses

figure
subplot(1, 2, 1)
plot(impulse(sysd, 0:N-1),'*-');
hold on;
plot(impulse(sysr, 0:N-1),'s-');
plot(impulse(sysp, 0:N-1),'o-');
hold off;
legend('Ground Truth', 'Reduced Fit', 'Full Fit')
xlabel('t');
ylabel('input and output signal');
title('Atomic norm approximation');

subplot(1, 2, 2)
hold on
stem3(real(p_sys), imag(p_sys), c_true)
stem3(real(poles_active), imag(poles_active), c(active_ind))

%unit circle

plot3(cos(th), sin(th), zeros(size(th)), 'color', [0 .5 0] )

hold off
axis square
view(3)
title(strcat('Pole Map (', num2str(nnz(c)), '/', num2str(length(c)),')'))

%legend groundtruth estimated
xlabel('Re(z)')
ylabel('Im(z)')
zlabel('Coefficients')

% %% hankelization
% nc = ceil(N/2);
% H_true = hankel(y(1:nc), y(nc:end));
% H = hankel(y_hat(1:nc), y_hat(nc:end));