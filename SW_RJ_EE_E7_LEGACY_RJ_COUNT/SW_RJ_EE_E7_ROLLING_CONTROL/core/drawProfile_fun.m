function p=drawProfile_fun(Y_hat,max_depth)


layers_num = (length(Y_hat)+1)/2;
h_inverted = Y_hat(layers_num+1:end);
Vs_inverted = Y_hat(1:layers_num);


% draw inverted profile
h_inverted_plot = [0 repelem(cumsum(h_inverted),2) max_depth];
Vs_inverted_plot = repelem(Vs_inverted,2);

p=plot(Vs_inverted_plot,h_inverted_plot,'Color','k','Linewidth',1);
hold on



