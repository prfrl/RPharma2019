# Clear workspace to avoid unintentional reuse of old variables
# ------------------------------------------------------------------------------
rm(list = ls())

# Then we define the functions needed to implement the ANN
# ------------------------------------------------------------------------------

# Dot product between two vectors
# a . b = a1b1 + a2b2 + ... + anbn
dot_prod = function(a, b){
  stopifnot( is.numeric(a) & is.numeric(b) & length(a) == length(b) )
  ab = 0
  for( i in seq(from = 1, to = length(a)) ){
    ab = ab + (a[i] * b[i])
  }
  return(ab)
}

# Matrix multiplication
# The dots products of the i'th row of A and the j'th column of B
mat_mult = function(A, B){
  stopifnot( is.numeric(A) & is.numeric(B) & ncol(A) == nrow(B) )
  AB = matrix(nrow = nrow(A), ncol = ncol(B))
  for( i in 1:nrow(A) ){
    for( j in 1:ncol(B) ){
      AB[i,j] = dot_prod(A[i,], B[,j])
    }
  }
  return(AB)
}

# Sigmoid activation function
# The function carrying the non-linearity of an ANN
s = function(x){ 1 / (1 + exp(-x)) }

# Mean squared error function
# Used to measure the difference between what the ANN predicts (O) and the
# target value (t)
mse = function(O, t){
  return( 1/2 * (O - t) ** 2 )
}

# Feed forward algorithm
# The process transforming the input vector to the prediction of the ANN
feed_forward = function(x, v, w){
  x = matrix(c(x, 1)) # Add bias neuron
  h = rbind(mat_mult(v, x), 1) # Add bias neuron
  H = s(h)
  o = mat_mult(w, H)[1,1]
  O = s(o)
  return(O)
}

# Prepare the data to work on. This is R, so naturally we will be using iris
# ------------------------------------------------------------------------------

# Take a moment to look at the data
head(iris)
dim(iris)

# iris contain 150 observations of the variables
# Sepal.Length, Sepal.Width, Petal.Length and Petal.Width (This is our X)
# and 3 flower species labels: setosa, versicolor, virginica (This is our y)
#
# We are going to model setosa yes/no, so we will prepare the data as follows:
X = iris[,-5] # Remove the labels to get our X
colnames(X) = paste0('x', seq(1, ncol(X))) # Create some nice column names
X = apply(X, 2, function(x){ return( as.numeric(scale(x)) ) }) # Scale obs
y = ifelse(iris$Species == 'setosa', 1, 0) # Set the label setosa yes/no
i = sample(seq(1, length(y))) # shuffle the rows of the data
X = X[i,] # Apply shuffling
y = y[i] # Apply shuffling

# The prepared data looks like so:
dim(X)
length(y)
head(X)
head(y)

# Recall the goal is to create a model, which takes the four input features
# x1, x2, x3 and x4 and correctly assigns setosa yes/no, i.e. a 1 if it indeed
# setosa and a 0 if it is not, so binary classification

# Now we are ready to train the network
# ------------------------------------------------------------------------------

# We start by setting the hyperparameters:
n_hidden = 1    # Number of hidden neurons (Only 1 hidden layer here)
epochs   = 5    # Number of epochs (Number of passes of entire data set)
epsilon  = 1000 # Learning rate (Step size, when adjusting the weights)

# And defining and initialising the the needed weight matrices

# Set dimensions for weight matrices
v_n_row = n_hidden     # to hidden layer
v_n_col = ncol(X) + 1  # From input layer
w_n_row = 1            # to output layer
w_n_col = n_hidden + 1 # From hidden layer

# Initialise weight matrices
# Note how weight are initialised randomly
v = matrix(data = rnorm(v_n_row * v_n_col), nrow = v_n_row, ncol = v_n_col)
w = matrix(data = rnorm(w_n_row * w_n_col), nrow = w_n_row, ncol = w_n_col)


# Now we are finally ready to run the training
# ------------------------------------------------------------------------------
# Run back propagation
training = matrix(NA, nrow = epochs, ncol = 2)
for( l in seq(1, epochs) ){
  
  errors = rep(NA, nrow(X))
  
  for( i in seq(1, nrow(X)) ){
    # Feed Forward
    x_i = matrix(c(X[i,], 1)) # Add bias neuron
    h   = rbind(mat_mult(v, x_i), 1) # Add bias neuron
    H   = s(h)
    o   = mat_mult(w, H)[1,1]
    O   = s(o)
    
    # Calculate error of current prediction
    y_i = y[i]
    err = mse(O, y_i)
    errors[i] = err
    
    # Calculate value of delta function
    s_prime_o = (1 - O) * O
    delta = (O - y_i) * s_prime_o
    
    # Compute w-weights changes
    dE_dw = t(delta * H)
    
    # Compute v-weights changes
    s_prime_h = (1 - H) * H
    dE_dv = matrix(data = NA, nrow = nrow(v), ncol = ncol(v))
    
    for( j in 1:nrow(dE_dv) ){
      
      for( k in 1:ncol(dE_dv) ){
        dE_dv[j,k] = delta * w[1,j] * s_prime_h[j,1] * x_i[k,1]
      }
    }
    
    # Update weight matrices
    w = w - epsilon * dE_dw
    v = v - epsilon * dE_dv
    
  }
  
  # Calculate mean errors for current epoch
  training[l,] = c(l, mean(errors))
  
}

# With the model we trained, we can predict on the training data and compare
# with the target values:

# Run predictions
# ------------------------------------------------------------------------------
y_true = y
y_pred = rep(NA, nrow(X))
for( i in seq(1, nrow(X)) ){
  y_pred[i] = feed_forward(X[i,], v, w)
}

# Calculate accuracy
# ------------------------------------------------------------------------------
thres = 0.5
y_pred_bin = (y_pred > thres) + 0
acc = sum(y_true == y_pred_bin) / length(y_true)
cat("Using ", n_hidden, " hidden neurons, a learning rate of ", epsilon,
    " and training for ", epochs, " epochs, you got an accuracy of ",
    round(acc, 3), "\n", sep = "")

# Lastly, we can visualise the training and the final performance of the model:

# Plot results
# ------------------------------------------------------------------------------
par(mfrow=c(1,2))
plot(training, type = "l", xlab="epoch", ylab = "MSE")
plot(cbind(y_pred, y_true))
abline(v = thres, lty = 2)
