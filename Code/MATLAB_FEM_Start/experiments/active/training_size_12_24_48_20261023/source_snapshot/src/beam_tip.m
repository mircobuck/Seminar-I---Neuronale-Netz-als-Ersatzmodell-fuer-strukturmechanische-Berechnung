function y=beam_tip(X)
I=X(:,2).*X(:,3).^3/12;
y=X(:,6).*X(:,1).^3./(3*X(:,4).*I);
end
