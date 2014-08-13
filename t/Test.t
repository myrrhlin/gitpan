#!/usr/bin/env perl

use lib 't/lib';
use Gitpan::perl5i;
use Gitpan::Test;

note "Using test config"; {
    use Gitpan::ConfigFile;
    my $config_file = Gitpan::ConfigFile->new;
    my $config = $config_file->config;

    ok $config_file->is_test;
    is $config->github_owner, 'gitpan-test';
}

note "The gitpan directory"; {
    use Gitpan::ConfigFile;
    my $config = Gitpan::ConfigFile->new->config;
    my $gitpan_dir = $config->gitpan_dir;

    ok -d $gitpan_dir,  "gitpan directory is created";

    # Check there are nothing but empty directories, because
    # Gitpan::Config will make them.
    my $iter = $gitpan_dir->iterator({ recurse => 1 });
    while( my $path = $iter->() ) {
        ok -d $path;
    }
}

done_testing;
