function features = rbfFeatures(inputs,centers,width)
%rbfFeatures Evaluate Gaussian bases with fixed centers and scalar width.
features=zeros(size(inputs,1),size(centers,1));
for k=1:size(centers,1)
    features(:,k)=exp(-sum((inputs-centers(k,:)).^2,2)/(2*width^2));
end
end
