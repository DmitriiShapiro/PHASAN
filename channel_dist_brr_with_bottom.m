clear all;

%compression gain fit parameters
p0 = -0.02655;
p1 = 0.9172;
p2 = 3.869;
p3 = 0.158;
q1 = 0.4925;
q2 = 0.00882;

%thermal distribution from BRR
       tp1 =  -1.434e-12;
       tp2 =  2.205e-10;
       tp3 =  -1.846e-09; 
       tp4 =  -1.107e-06;
       tp5 =  4.85e-05;

for jjj=1:5 %staircase cycle
    
    S_N = jjj; %number of staircases
    staircase_number(jjj) = jjj;

    for jj=1:3 %walls cycle

        if jj==1
            wall_thick = 0;
        end
        if jj==2
            wall_thick = 0.1;
        end
        if jj==3
            wall_thick = 0.05;
        end


        for iiii=3:3 %source type cucle - here we use only BRR channel


            for iii=1:1 %neutron energy cucle

                lambda = 10; %mean free path in cm

                for ii=1:2 %moderator width cycle

                    if ii==1
                        W = 3;
                    end
                    if ii==2
                        W = 10;
                    end

                    for l=1:5 %number of steps cycle
                        
                        N = l;
                        if l == 4
                            N = 5; %4 steps are not calculated, instead we run 5 steps
                        end
                        if l == 5
                            N = 7; %5 steps are not calculated, instead we run 7 steps
                        end

                        %even in case of multiple staircases, tube-like
                        %moderator is used as a reference
                        if N > 1
                            compression_factor = (p0*(W/N)^3 + p1*(W/N)^2 + p2*(W/N) + p3)/((W/N)^2 + q1*(W/N) + q2)*(p0*(W/S_N)^3 +p1*(W/S_N)^2 + p2*(W/S_N) + p3)/((W/S_N)^2 + q1*(W/S_N) + q2); 
                        else
                            compression_factor = (p0*(W/N)^3 + p1*(W/N)^2 + p2*(W/N) + p3)/((W/N)^2 + q1*(W/N) + q2)*(p0*(W)^3 +p1*(W)^2 + p2*(W) + p3)/((W)^2 + q1*(W) + q2);
                        end

                        %check if walls occupy the whole width
                        wall_factor = 1 - wall_thick*(N-1)/W*S_N;
                        if wall_factor < 0
                            wall_factor = 0;
                        end

                        for i=1:60 %step length cycle

                            mod_length(i) = i;

                            total_int = 0;

                            for j=1:l %calculating total cold intensity going through each of the steps

                                step_int = 0;

                                for k=1:mod_length(i) %integrating over step length
             
                                    dist(k) = mod_length(i)/2 + mod_length(i)*(j-1) + k;

                                    if dist(k) > 90
                                        position_factor(k) = 0;
                                    else
                                        position_factor(k) = tp1*dist(k).^4+tp2*dist(k).^3+tp3*dist(k).^2+tp4*dist(k)+tp5;
                                    end


                                    %taking into account bottom
                                    %contribution
                                    if k == 1
                                        
                                        bottom_int = position_factor(k)/(2*W/N/jjj + 2*10)*W/N/jjj*10;
                                        step_int = step_int + bottom_int;

                                    end

                                    step_int = step_int*exp(-1/lambda) + position_factor(k);

                                end

                                total_int = total_int + step_int;


                            end

                            average_bril = total_int/N;

                            brilliance(l,i) = compression_factor * average_bril *wall_factor;
                            if l>1
                                brilliance(l,i) = brilliance(l,i)*0.9; %shadowing effect
                            end

                        end

                    end

                    brilliance = brilliance/max(brilliance(1,:));
                    
                    max_gain(jjj,jj,iiii,iii,ii) = max(max(brilliance));

                    f = figure('visible','off');
                    f.Position(1:4) = [100, 100, 1200, 1000];
                    plot(mod_length, brilliance,'LineWidth',6.0);
                    set(gca, 'FontSize', 30);
                    xlabel('Step length, cm','FontSize', 30);
                    ylabel('Brilliance gain','FontSize', 30);
                    
                    if S_N == 1
                        title("BRR, 1 staircase, W = "+num2str(W)+"cm, MFP = "+num2str(lambda)+"cm, walls "+num2str(wall_thick*10)+"cm",'FontSize', 30);
                    else
                        title("BRR, "+num2str(S_N)+" staircases, W = "+num2str(W)+"cm, MFP = "+num2str(lambda)+"cm, walls "+num2str(wall_thick*10)+"mm",'FontSize', 30);
                    end

                    legend({'1 step','2 steps', '3 steps', '5 steps', '7 steps'}, 'FontSize', 30);
                    grid on;
                    
                    saveas(gcf,"../PIK CNS/figures_brr_with_bottom/staircase"+num2str(S_N)+"_W"+num2str(W)+"_MFP"+num2str(lambda)+"_wall"+num2str(wall_thick)+".png");
                    saveas(gcf,"../PIK CNS/figures_brr_with_bottom/staircase"+num2str(S_N)+"_W"+num2str(W)+"_MFP"+num2str(lambda)+"_wall"+num2str(wall_thick)+".fig");

                    
                end
            end
        end
    end
end