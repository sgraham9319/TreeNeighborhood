context("Density calculation")


# Needed columns: stand_id, species, dbh, x_coord, y_coord
# To test whether the data frame output by your function (outdat) is identical
# to the data frame you expect in this case (dat - created manually)
# expect_true(identical(dat, outdat))



test_that("Output data frame as expected", {
  expect_equal(density_expected(), density_test(fake_map(), "A"))
})