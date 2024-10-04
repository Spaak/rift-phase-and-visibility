t = 0:0.0005:0.1;
f = 62;

ylims = [-0.1 1.1];

figure();

whitesig = sin(2*pi*f*t)/2 + 0.5;
blacksig = zeros(size(whitesig));
subplot(1, 5, 1);
plot(t, whitesig, 'w', t, blacksig, 'k', 'linewidth', 2);
set(gca, 'color', [0.5 0.5 0.5]);
ylim(ylims);
box off;
title('Tagging type 1');
xlabel('Time (s)');
ylabel('Luminance');


whitesig = sin(2*pi*f*t)/4 + 0.75;
blacksig = zeros(size(whitesig));
subplot(1, 5, 2);
plot(t, whitesig, 'w', t, blacksig, 'k', 'linewidth', 2);
set(gca, 'color', [0.5 0.5 0.5]);
ylim(ylims);
box off;
title('Tagging type 2');
set(gca, 'yticklabel', []);

whitesig = sin(2*pi*f*t)/4 + 0.75;
blacksig = sin(2*pi*f*t)/4 + 0.25;
subplot(1, 5, 3);
plot(t, whitesig, 'w', t, blacksig, 'k', 'linewidth', 2);
set(gca, 'color', [0.5 0.5 0.5]);
ylim(ylims);
box off;
title('Tagging type 3');
set(gca, 'yticklabel', []);

whitesig = sin(2*pi*f*t)/4 + 0.75;
blacksig = sin(2*pi*f*t+pi)/4 + 0.25;
subplot(1, 5, 4);
plot(t, whitesig, 'w', t, blacksig, 'k', 'linewidth', 2);
set(gca, 'color', [0.5 0.5 0.5]);
ylim(ylims);
box off;
title('Tagging type 4');
set(gca, 'yticklabel', []);

whitesig = ones(size(t));
blacksig = zeros(size(t));
subplot(1, 5, 5);
plot(t, whitesig, 'w', t, blacksig, 'k', 'linewidth', 2);
set(gca, 'color', [0.5 0.5 0.5]);
ylim(ylims);
box off;
title('No tagging');
set(gca, 'yticklabel', []);

annotation(gcf, 'rectangle', [0 0 1 1], 'color', 'w');

%%

exportgraphics(gcf, '../plots/illustrations-tagtypes.pdf', 'contenttype', 'vector');
