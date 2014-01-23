function out = equivHOG(orig, n, gam, sig, pd),

orig = im2double(orig);
feat = features(orig, 8);

if ~exist('n', 'var'),
  n = 6;
end
if ~exist('gam', 'var'),
  gam = 1;
end
if ~exist('sig', 'var'),
  sig = 10;
end
if ~exist('si', 'var'),
  si = .1;
end

bord = 5;
[ny, nx, nf] = size(feat);
numwindows = (ny+12-pd.ny+1)*(nx+12-pd.nx+1);

fprintf('ihog: attempting to find %i equivalent images in HOG space\n', n);

prev = zeros(pd.k, numwindows, n);
ims = ones((ny+2)*8, (nx+2)*8, n);
hogs = zeros(ny, nx, nf, n);
dists = zeros(n, 1);

for i=1:n,
  fprintf('ihog: searching for image #%i\n', i);
  [im, a] = invertHOG(feat, prev(:, :, 1:i-1), gam, sig, pd);

  ims(:, :, i) = im;
  hogs(:, :, :, i) = features(repmat(im, [1 1 3]), 8);
  prev(:, :, i) = a;

  figure(1);
  subplot(122);
  imagesc(repmat(imdiffmatrix(ims(:, :, 1:i), orig, 5), [1 1 3]));
  axis image;

  subplot(321);
  sparsity = mean(reshape(double(prev(:, :, 1:i) == 0), [], i));
  plot(1-sparsity(:), '-*');
  title('Alpha Density');
  ylabel('Density');

  subplot(323);
  dists = squareform(pdist(reshape(hogs(:, :, :, 1:i), [], i)'));
  dists = sqrt(dists / (ny*nx*nf));
  imagesc(dists);
  title('HOG Distance Matrix');
  colorbar;

  subplot(325);
  imagesc(hogimvis(ims(:, :, 1:i), hogs(:, :, :, 1:i)));
  axis image;

  colormap gray;
  drawnow;
end

out = ims;


function im = imdiffmatrix(ims, orig, bord),

[h, w, n] = size(ims);
im = ones(h*(n+1), w*(n+1));

orig = imresize(orig, [h w]);
orig(orig > 1) = 1;
orig(orig < 0) = 0;
orig = mean(orig, 3);
orig = padarray(orig, [bord bord], .5);

h = h + 2 * bord;
w = w + 2 * bord;

% build borders
for i=1:n,
  im(h*i:h*(i+1)-1, 1:w) = padarray(ims(:, :, i), [bord bord], .5);
  im(1:h, w*i:w*(i+1)-1) = padarray(ims(:, :, i), [bord bord], .5);
end

im(1:h, 1:w) = orig;

for i=1:n,
  for j=1:n,
    d = abs(ims(:, :, i) - ims(:, :, j));
    d(:) = d(:) * 2;
    d = min(d, 1);
    d = padarray(d, [bord bord], 1);
    im(h*j:h*(j+1)-1, w*i:w*(i+1)-1) = d;
  end
end



function out = hogimvis(ims, hogs),

out = [];
for i=1:size(ims,3),
  im = ims(:, :, i);
  hog = hogs(:, :, :, i);
  hog(:) = max(hog(:) - mean(hog(:)), 0);
  hog = showHOG(hog);
  hog = imresize(hog, size(im));
  hog(hog > 1) = 1;
  hog(hog < 0) = 0;
  im = padarray(im, [5 10], 1);
  hog = padarray(hog, [5 10], 1);
  graphic = [im; hog];
  out = [out graphic];
end
out = padarray(out, [5 0], 1);
