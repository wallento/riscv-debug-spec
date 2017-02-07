CC=$(RISCV)/bin/riscv64-unknown-elf-gcc

NAME=riscv-debug-spec

REGISTERS_TEX = jtag_registers.tex
REGISTERS_TEX += core_registers.tex
REGISTERS_TEX += hwbp_registers.tex
REGISTERS_TEX += dm1_registers.tex
REGISTERS_TEX += dm2_registers.tex
REGISTERS_TEX += trace_registers.tex
REGISTERS_TEX += sample_registers.tex
REGISTERS_TEX += abstract_commands.tex

FIGURES = *.eps

riscv-debug-spec.pdf: $(NAME).tex $(REGISTERS_TEX) debug_rom.S $(FIGURES) vc.tex changelog.tex
	pdflatex -shell-escape $< && pdflatex -shell-escape $<

publish:	riscv-debug-spec.pdf
	cp $< riscv-debug-spec-`git rev-parse --abbrev-ref HEAD`.`git rev-parse --short HEAD`.pdf

vc.tex: .git/logs/HEAD
	# https://thorehusfeldt.net/2011/05/13/including-git-revision-identifiers-in-latex/
	echo "%%% This file is generated by Makefile." > vc.tex
	echo "%%% Do not edit this file!\n%%%" >> vc.tex
	git log -1 --format="format:\
	    \\gdef\\GITHash{%H}\
	    \\gdef\\GITAbrHash{%h}\
	    \\gdef\\GITAuthorDate{%ad}\
	    \\gdef\\GITAuthorName{%an}" >> vc.tex

changelog.tex: .git/logs/HEAD Makefile
	echo "%%% This file is generated by Makefile." > changelog.tex
	echo "%%% Do not edit this file!\n%%%" >> changelog.tex
	git log --date=short --pretty="format:\\vhEntry{%h}{%ad}{%an}{%s}" | \
	    sed s,_,\\\\_,g | sed "s,#,\\\\#,g" >> changelog.tex

%.eps: %.dot
	dot -Teps $< -o $@

%.tex: %.xml registers.py
	./registers.py --custom --definitions $@.inc --cheader $(basename $@).h $< > $@

%.o:	%.S
	$(CC) -c $<

# Remove 128-bit instructions since our assembler doesn't like them.
%_no128.S:	%.S
	sed "s/\([sl]q\)/nop\#\1/" < $< > $@

debug_rom:	debug_rom_no128.o main.o
	$(CC) -o $@ $^ -Os

debug_ram:	debug_ram.o main.o
	$(CC) -o $@ $^

hello:	hello.c
	$(CC) -o $@ $^ -Os

hello.s:	hello.c
	$(CC) -o $@ $^ -S -Os

clean:
	rm -f $(NAME).pdf $(NAME).aux $(NAME).toc $(NAME).log $(REGISTERS_TEX) \
	    $(REGISTERS_TEX:=.inc) *.o *_no128.S *.h $(NAME).lof $(NAME).lot $(NAME).out \
	    $(NAME).hst $(NAME).pyg
