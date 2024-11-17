if exist ..\ram32x4.mif (
    copy /Y ..\ram32x4.mif .
)
if exist ..\ram32x4_bb.v (
    del ..\ram32x4_bb.v
)
if exist work rmdir /S /Q work

vlib work
vlog ../tb/*.v
vlog ../*.v
