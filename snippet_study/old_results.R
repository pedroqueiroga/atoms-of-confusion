library("RSQLite")
#library("fitdistrplus")
library(DBI)
library("data.table")
#library('plyr')
library('manipulate')
library('animation')
#library(gridExtra)
#library(grid)
library(operators)
library(xtable)

pis.nan.data.frame <- function(x) do.call(cbind, lapply(x, is.nan))

# Coefficient of Variability, measure of dispersion/relative variability:
# http://alstatr.blogspot.com/2013/06/measure-of-relative-variability.html
CV <- function(vec) sd(vec)/mean(vec)

con <- dbConnect(drv=RSQLite::SQLite(), dbname="confusion.db")
query.from.file <- function(filename) {
  query <- paste(readLines(filename), collapse = "\n")
  dbGetQuery( con, query )
}

queryRes <- query.from.file('sql/first_cluster_contingency.sql')

alpha <- 0.05

phi <- function(chi2, n) {
  sqrt(chi2/n)
}

printContingency <- function(name, alpha, res, contingency) {
  sig <- is.significant(res, alpha)
  es <- phi(res$statistic, sum(contingency))
  contStr <- paste(format(contingency, width=3), collapse=" ")
  
  writeLines(sprintf("%-35s: %d - (p:%.2e, es:%0.2f)  (%s)", name, sig, res$p.value, es, contStr))
  
  NULL
}

is.significant <- function(res, alpha) {
  is.finite(res$p.value) && res$p.value < alpha
}

toDF <- function (mcnemarsRes) {
  mcnemarsFrame <- as.data.frame(matrix(unlist(mcnemarsRes), ncol=length(unlist(mcnemarsRes[1])), byrow=T))
  #colnames(mcnemarsFrame) <- attributes(mcnemarsRes[[1]])$names
  mcnemarsFrame
}

#byQuestion <- function(queryRes) {
  # print p-value and effect size for each question
  contingencyTables <- mapply(function(a,b,c,d) matrix(c(a,b,c,d), 2, 2), queryRes$TT,  queryRes$TF, queryRes$FT,queryRes$FF, SIMPLIFY = FALSE)
  mcnemarsRes <- lapply(contingencyTables, function(x) mcnemar.test(x, correct=FALSE))
  ignore <- mapply(printContingency, queryRes$question, alpha, mcnemarsRes, contingencyTables)
  
  # how many questions were significant for each atom type
  mcnemarsFrame <-toDF(mcnemarsRes)
  colnames(mcnemarsFrame) <- attributes(mcnemarsRes[[1]])$names
  
  mcnemarsFrame$questionName <- queryRes$question
  mcnemarsFrame$atomName <- queryRes$atom
  mcnemarsFrame$contingencies <- contingencyTables
  mcnemarsFrame$effectSize <- apply(mcnemarsFrame, 1, function(x) phi(as.numeric(x$statistic), sum(x$contingencies)))
  mcnemarsFrame$effectSize[is.nan(mcnemarsFrame$effectSize)] <- 0
  
  dt <- data.table(mcnemarsFrame)
  print("# significant questions")
  print(dt[, length(questionName[as.numeric(as.character(p.value)) < alpha]), by = atomName])
  
  # variance of question triplets
  print("Effect size std.dev. amoung questions")
  effectSdByAtom <- dt[, sd(effectSize), by = atomName]
  effectVarByAtom <- dt[, var(effectSize), by = atomName]
  effectCoeffVarByAtom <- dt[, CV(effectSize), by = atomName]
  print(effectSdByAtom)
#}

runMcnemars <- function(contingency) {
  mcnemarsRes <- mcnemar.test(contingency, correct=FALSE)
  es <- phi(mcnemarsRes$statistic, sum(contingency))
  list('contingency' = contingency, 'mcnemarsRes' = mcnemarsRes, 'effectSize' = es)
}

processAtom <- function(atomName) {
    sign <- queryRes[queryRes$atom == atomName,]
    
    contingency <- matrix(c(sum(sign$TT), sum(sign$TF), sum(sign$FT), sum(sign$FF)), 2, 2)
    mcRes <- runMcnemars(contingency)
    mcRes$atomName <- atomName
    mcRes
}

#byAtom <- function(queryRes) {
  writeLines(sprintf("%-35s: sig. - (pvalue, effectSize)  (TT TF FT FF)", "atom"))
  
  alpha <- 0.05

  atomRes <- lapply(unique(queryRes$atom), processAtom)
  
  invisible(lapply(atomRes, function (r) printContingency(r$atomName, alpha, r$mcnemarsRes, r$contingency)))

  atomFrame <- data.table(toDF(atomRes))
  colnames(atomFrame) <- c('TT', 'TF', 'FT', 'FF', "statistic", "parameter", "p.value", "method", "data.name", "effect.size", "atomName")
  atomFrame$atomName <- atomFrame[,as.character(atomName)]
  atomFrame$effect.size <- atomFrame[,as.numeric(as.character(effect.size))]
  atomFrame$p.value <- atomFrame[,as.numeric(as.character(p.value))]
  
  
  # Remove old atom types
  atomFrame <- atomFrame[atomFrame[,!atomName %in% c("remove_INDENTATION_atom", "Indentation")]]
  
  # Rename the atoms
  name.conversion <- list(
    "add_CONDITION_atom"            = "Implicit Predicate",
    "add_PARENTHESIS_atom"          = "Infix Operator Precedence",
    "move_POST_INC_DEC_atom"        = "Post-Increment/Decrement",
    "move_PRE_INC_DEC_atom"         = "Pre-Increment/Decrement",
    "replace_CONSTANTVARIABLE_atom" = "Constant Variables",
    "replace_MACRO_atom"            = "Macro Operator Precedence",
    "replace_Ternary_Operator"      = "Conditional Operator",
    "replace_Arithmetic_As_Logic"   = "Arithmetic as Logic",
    "replace_Comma_Operator"        = "Comma Operator",
    "Constant Assignment"           = "Assignment as Value",
    "Logic as Control Flow"         = "Logic as Control Flow",
    "Re-purposed variables"         = "Repurposed Variables",
    "Swapped subscripts"            = "Reversed Subscripts",
    "Dead, unreachable, repeated"   = "Dead, Unreachable, Repeated",
    "Literal encoding"              = "Change of Literal Encoding",
    "Curly braces"                  = "Omitted Curly Braces",
    "Type conversion"               = "Type Conversion",
    "move_Preprocessor_Directives_Inside_Statements" = "Preprocessor in Expression",
    "replace_Mixed_Pointer_Integer_Arithmetic" = "Pointer Arithmetic"
    #  "Indentation",
    #  "remove_INDENTATION_atom",
  )
  
  atomFrame[, prettyName := name.conversion[atomName],]
  
  #atomFrame
#}

#byQuestion(queryRes)

#atomFrame <- byAtom(queryRes)

#x <- atomFrame$V11
#y <- effectSdByAtom$V1
#x <- effectCoeffVarByAtom$atomName
#y <- effectCoeffVarByAtom$V1

#l <- atomFrame$V1
#plot(x, y, xlab="effect size", ylab="sd of effect size")
#text(x,y,labels=l, srt = -25)

#stripchart(y, at=0.7); text(y, 0.72, labels=l, srt=90, cex=1.5, adj=c(0,0))

triplet <- dt[atomName=='move_POST_INC_DEC_atom', ]
#lapply(triplet$questionName, function(a) triplet[questionName != a, questionName])
#apply(triplet, 1, function(a) triplet[questionName != a$questionName, questionName])

#apply(triplet, 1, function(a) {
#  m <- mean(triplet$effectSize)
#  triplet[questionName != a$questionName &
#          abs(effectSize - a$effectSize)/m < .2, questionName]
#})

neighbors <- function(thresh) {
  nbrsRes <- apply(dt, 1, function(a) {
    triplet <- dt[atomName==a$atomName, ]
    m <- mean(triplet$effectSize)
    aqn <- a$questionName
    nbrs <- triplet[questionName != aqn &
                abs(effectSize - a$effectSize) < thresh, questionName] # could (and should) be implemented in terms of the dist column below
    
    dist <- min(triplet[questionName != aqn, abs(effectSize - a$effectSize)])
    
    list(aqn, nbrs, dist)
  })
  
  
  nbrsList <- list(lapply(nbrsRes, '[[', 1), lapply(nbrsRes, '[[', 2), lapply(nbrsRes, '[[', 3))
  nbrsDT <- data.table(questionName=unlist(nbrsList[1]), neighbors=nbrsList[[2]], dist=nbrsList[[3]])
  nbrsDT$len <- lapply(nbrsDT$neighbors, length)
  nbrsDT
}


# mcTable <- nonOrphanContingencies
# mcRes <- null
applyMcnemars <- function(mcTable) {
  #mcTable[, runMcnemars(Reduce("+", contingencies)), by='atomName']
  # mcTable[, .SD[, Reduce("+", contingencies)], by='atomName']

  mcTable$TT <- lapply(mcTable$contingencies, '[[', 1)
  mcTable$TF <- lapply(mcTable$contingencies, '[[', 2)
  mcTable$FT <- lapply(mcTable$contingencies, '[[', 3)
  mcTable$FF <- lapply(mcTable$contingencies, '[[', 4)
  
  contingencies <- mcTable[, .("TT" = Reduce('+', TT), "TF" = Reduce('+', TF), "FT" = Reduce('+', FT), "FF" = Reduce('+', FF)), by='atomName']
  contingencyTables <- mapply(function(a,b,c,d) matrix(c(a,b,c,d), 2, 2), contingencies$TT,  contingencies$TF, contingencies$FT,contingencies$FF, SIMPLIFY = FALSE)
  # View(contingencyTables)
  
  mcRes <- lapply(contingencyTables, runMcnemars)

  contingencies$statistic <- lapply(lapply(mcRes, '[[', 'mcnemarsRes'), '[[', 'statistic')
  contingencies$p.value <- lapply(lapply(mcRes, '[[', 'mcnemarsRes'), '[[', 'p.value')
  contingencies$effectSize <- lapply(mcRes, '[[', 'effectSize')

  contingencies
}

csvView <- function(odt) {
  odtView <- odt[,c(attributes(odt)$names[[1]], "p.value", "effectSize","TT", "TF", "FT", "FF"), with=FALSE]
  data.frame(lapply(odtView, as.character), stringsAsFactors=FALSE)
}

nc <- function(x) as.numeric(as.character(x))

atomFrame$total <- atomFrame[, nc(TT) + nc(TF) + nc(FT) + nc(FF)]

atomFrame$c.incorrect.rate <- atomFrame[, (nc(FT) + nc(FF)) / total]

snippet.results <- atomFrame[, .(
  "Atom" = prettyName,
  "Effect" = sprintf("%3.2f", effect.size),
  "p-value"= paste(ifelse(p.value < alpha, '\\textbf{', "{"), sprintf(ifelse(p.value < 0.1, "%0.2e", "%0.2f"), p.value), "}", sep='')
  # ,"Accept"= ifelse(p.value<alpha,"T","F")
  )]
setorder(snippet.results, -"Effect")
print(xtable(snippet.results), include.rownames=FALSE, sanitize.text.function=identity)
